import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_client.dart';

enum SocialProvider { google, apple }

/// The user backed out of the provider's sheet. Not an error — the caller
/// should return to the form silently rather than show a message.
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// Anything worth putting in front of the user.
class SocialSignInException implements Exception {
  const SocialSignInException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Native Google and Apple sign-in on top of Supabase's ID-token grant.
///
/// Both providers hand back an OIDC ID token that gotrue verifies directly, so
/// there is no browser round trip and no deep-link redirect to configure.
///
/// The catch is that an ID-token sign-in always lands on its own user id — it
/// cannot upgrade the anonymous session in place the way the email path's
/// `updateUser` does. A guest signing in with Google would otherwise walk away
/// from their streak, saves and prayers. [signIn] therefore books a merge
/// token before handing off to the provider and redeems it afterwards; see
/// `supabase/migrations/0004_account_merge.sql` for why it is a token and not
/// just a user id.
class SocialAuth {
  const SocialAuth._();

  static bool _googleReady = false;

  /// Google needs the Web client ID everywhere, plus the iOS client ID on iOS.
  /// The button stays hidden while either is missing — a "Continue with
  /// Google" that can only fail is worse than no button at all, and App Review
  /// treats it as an incomplete feature (guideline 2.1).
  static bool get isGoogleConfigured {
    if (AppEnv.googleServerClientId.isEmpty) return false;
    if (!kIsWeb && Platform.isIOS && AppEnv.googleIosClientId.isEmpty) {
      return false;
    }
    return true;
  }

  /// Sign in with Apple is only native on Apple platforms. On Android it would
  /// need a web redirect flow and its own Services ID, which the app does not
  /// carry, so the button is hidden there instead.
  static bool get isAppleConfigured =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  /// Runs the provider flow and leaves a signed-in Supabase session behind.
  ///
  /// Throws [SocialSignInCancelled] if the user dismissed the provider sheet,
  /// or [SocialSignInException] with a message fit to display.
  static Future<void> signIn(SocialProvider provider) async {
    final previous = supa.auth.currentUser;
    final mergeToken =
        (previous?.isAnonymous ?? false) ? await _issueMergeToken() : null;

    final credential = switch (provider) {
      SocialProvider.google => await _googleCredential(),
      SocialProvider.apple => await _appleCredential(),
    };

    try {
      await supa.auth.signInWithIdToken(
        provider: switch (provider) {
          SocialProvider.google => OAuthProvider.google,
          SocialProvider.apple => OAuthProvider.apple,
        },
        idToken: credential.idToken,
        nonce: credential.nonce,
      );
    } on AuthException catch (e) {
      throw SocialSignInException(e.message);
    }

    final user = supa.auth.currentUser;
    if (user == null) {
      throw const SocialSignInException('Sign-in did not complete — try again');
    }

    if (mergeToken != null && user.id != previous?.id) {
      await _claimMergeToken(mergeToken);
    }
    await _backfillName(user, credential.name);
  }

  /// Clears the Google SDK's own cached account, so the next sign-in shows the
  /// account picker instead of silently reusing the last one. Supabase's
  /// `signOut` knows nothing about it.
  static Future<void> signOutProviders() async {
    if (!_googleReady) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('google sign-out failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Providers
  // ---------------------------------------------------------------------------

  static Future<({String idToken, String? nonce, String? name})>
      _googleCredential() async {
    if (!isGoogleConfigured) {
      throw const SocialSignInException(
          'Google sign-in isn’t configured for this build');
    }

    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId:
            AppEnv.googleIosClientId.isEmpty ? null : AppEnv.googleIosClientId,
        serverClientId: AppEnv.googleServerClientId,
      );
      _googleReady = true;
    }
    if (!google.supportsAuthenticate()) {
      throw const SocialSignInException(
          'Google sign-in isn’t supported on this device');
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      debugPrint('google authenticate failed: ${e.code} ${e.description}');
      throw const SocialSignInException(
          'Google couldn’t sign you in — try again');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const SocialSignInException('Google didn’t return an ID token');
    }
    return (idToken: idToken, nonce: null, name: account.displayName);
  }

  static Future<({String idToken, String? nonce, String? name})>
      _appleCredential() async {
    // Apple signs the hash; Supabase re-hashes the raw value to check it. The
    // pair is what stops a stolen token being replayed.
    final rawNonce = supa.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelled();
      }
      debugPrint('apple authorization failed: ${e.code} ${e.message}');
      throw const SocialSignInException(
          'Apple couldn’t sign you in — try again');
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const SocialSignInException('Apple didn’t return an identity token');
    }

    // Apple releases the name on the *first* authorization only, and never
    // again — so this is the one chance to capture it.
    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .join(' ')
        .trim();
    return (
      idToken: idToken,
      nonce: rawNonce,
      name: name.isEmpty ? null : name,
    );
  }

  // ---------------------------------------------------------------------------
  // Guest carry-over
  // ---------------------------------------------------------------------------

  static Future<String?> _issueMergeToken() async {
    try {
      return await supa.rpc('issue_merge_token') as String?;
    } catch (e) {
      // Not fatal: the sign-in itself still works, the guest's rows just stay
      // behind. Failing the whole flow over it would be the worse trade.
      debugPrint('issue_merge_token failed: $e');
      return null;
    }
  }

  static Future<void> _claimMergeToken(String token) async {
    try {
      await supa.rpc('claim_merge_token', params: {'p_token': token});
    } catch (e) {
      debugPrint('claim_merge_token failed: $e');
    }
  }

  /// Seeds the profile name from the provider when we have one and the profile
  /// doesn't. Never overwrites a name the user set themselves.
  static Future<void> _backfillName(User user, String? name) async {
    if (name == null || name.isEmpty) return;
    try {
      final row = await supa
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final existing = row?['full_name'] as String?;
      if (existing != null && existing.isNotEmpty) return;
      await supa.from('profiles').update({'full_name': name}).eq('id', user.id);
    } catch (e) {
      debugPrint('profile name backfill failed: $e');
    }
  }
}
