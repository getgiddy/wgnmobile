import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/auth_state.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../../data/user_state.dart';
import 'social_auth.dart';

/// Guest → account upgrade (links email onto the anonymous session so likes,
/// streaks and downloads carry over) or plain sign-in.
void showAuthSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AuthSheet(),
  );
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet();

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signIn = false;
  bool _busy = false;
  String? _error;

  /// Which provider sheet is open, so only that button shows a pending label.
  SocialProvider? _pendingSocial;

  /// Set when sign-up succeeded but left no session, so the sheet shows what
  /// has to happen next instead of the form.
  String? _confirmationSentTo;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Enter an email and a password (6+ characters)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      if (_signIn) {
        await supa.auth.signInWithPassword(email: email, password: password);
      } else if (supa.auth.currentUser?.isAnonymous ?? false) {
        // Upgrade the anonymous session in place, so the guest's streak,
        // saves and registrations stay on the same user id. The session stays
        // valid whether or not confirmation is required.
        await supa.auth.updateUser(UserAttributes(
          email: email,
          password: password,
          data: {'full_name': name},
        ));
      } else {
        // No guest session to upgrade — anonymous sign-ins may be disabled on
        // the project, or startup was offline. Without this fallback the only
        // route to an account dead-ends on "Auth session missing!".
        final res = await supa.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
        if (res.session == null) {
          // Confirmation required, and no guest session to fall back on: the
          // account exists but nobody is signed in, and gotrue will refuse
          // signInWithPassword with `email_not_confirmed` until the link is
          // clicked. Saying "you're all set" here would be a flat lie.
          setState(() => _confirmationSentTo = email);
          return;
        }
      }
      final uid = supa.auth.currentUser?.id;
      if (uid != null && !_signIn && name.isNotEmpty) {
        await supa.from('profiles').update({'full_name': name}).eq('id', uid);
      }
      await _finish(_signIn
          ? 'Welcome back'
          : (ref.read(awaitingEmailConfirmationProvider)
              ? 'Account created — check your inbox to confirm'
              : 'Account created — you’re all set'));
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong — try again');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _social(SocialProvider provider) async {
    setState(() {
      _pendingSocial = provider;
      _error = null;
    });
    try {
      await SocialAuth.signIn(provider);
      await _finish('Welcome — you’re signed in');
    } on SocialSignInCancelled {
      // Backing out of the provider sheet is not a failure; leave the form as
      // it was so they can pick another route.
    } on SocialSignInException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      debugPrint('social sign-in failed: $e');
      setState(() => _error = 'Something went wrong — try again');
    } finally {
      if (mounted) setState(() => _pendingSocial = null);
    }
  }

  /// Shared tail of every successful route into an account.
  Future<void> _finish(String message) async {
    ref.invalidate(profileProvider);
    ref.invalidate(myPrayersProvider);
    await ref.read(userStateProvider.notifier).reload();
    if (!mounted) return;
    Navigator.of(context).pop();
    ref.read(toastProvider.notifier).show(message);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final social = [
      if (SocialAuth.isGoogleConfigured) SocialProvider.google,
      if (SocialAuth.isAppleConfigured) SocialProvider.apple,
    ];
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: c.nav,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: c.line),
        ),
        child: _confirmationSentTo != null
            ? _confirmationNotice(c)
            : _form(c, social),
      ),
    );
  }

  /// Shown when the account was created but no session came back, so the user
  /// is not signed in and cannot be until they confirm.
  Widget _confirmationNotice(WgnColors c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Check your inbox', style: WgnText.display(19, color: c.txt)),
          const SizedBox(height: 6),
          Text(
            'We sent a confirmation link to $_confirmationSentTo. Open it to '
            'finish setting up your account, then come back and sign in.',
            style: WgnText.ui(11.5, color: c.txt2, height: 1.5),
          ),
          const SizedBox(height: 20),
          WgnButton(
            label: 'Done',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => setState(() {
                _confirmationSentTo = null;
                _signIn = true;
                _error = null;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Already confirmed? Sign in',
                  style:
                      WgnText.ui(11.5, weight: FontWeight.w600, color: c.gold),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _form(WgnColors c, List<SocialProvider> social) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_signIn ? 'Sign in' : 'Create your account',
                style: WgnText.display(19, color: c.txt)),
            const SizedBox(height: 6),
            Text(
              _signIn
                  ? 'Pick up your streaks, saves and giving history.'
                  : 'Keeps your streak, saves and registrations across devices.',
              style: WgnText.ui(11.5, color: c.txt2, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (!_signIn) _field(_name, 'Full name'),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress),
            _field(_password, 'Password', obscure: true),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style: WgnText.ui(11.5,
                        color: const Color(0xFFE0483B), height: 1.4)),
              ),
            WgnButton(
              label: _busy
                  ? 'One moment…'
                  : (_signIn ? 'Sign in' : 'Create account'),
              onTap: _busy || _pendingSocial != null ? null : _submit,
            ),
            // Each button is hidden unless its provider is actually usable in
            // this build, so an unconfigured deployment shows fewer routes
            // rather than ones that can only fail.
            if (social.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final provider in social) ...[
                    if (provider != social.first) const SizedBox(width: 10),
                    Expanded(child: _oauthButton(provider)),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _signIn = !_signIn;
                  _error = null;
                }),
                child: Text(
                  _signIn
                      ? 'New here? Create an account'
                      : 'Already have an account? Sign in',
                  style: WgnText.ui(11.5,
                      weight: FontWeight.w600, color: c.gold),
                ),
              ),
            ),
          ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
    final c = context.wgn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        autocorrect: false,
        style: WgnText.ui(13, color: c.txt),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          hintText: hint,
          hintStyle: WgnText.ui(13, color: c.txt3),
        ),
      ),
    );
  }

  Widget _oauthButton(SocialProvider provider) {
    final c = context.wgn;
    final label = switch (provider) {
      SocialProvider.google => 'Google',
      SocialProvider.apple => 'Apple',
    };
    final pending = _pendingSocial == provider;
    // Any flow in progress locks the others, so two provider sheets can never
    // race each other onto the same session.
    final locked = _busy || _pendingSocial != null;
    return GestureDetector(
      onTap: locked ? null : () => _social(provider),
      child: Opacity(
        opacity: locked && !pending ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: c.line2),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            pending ? 'One moment…' : 'Continue with $label',
            style: WgnText.ui(11.5, weight: FontWeight.w600, color: c.txt2),
          ),
        ),
      ),
    );
  }
}
