import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase endpoints.
///
/// Release builds must supply both values — there is no fallback, so a
/// misconfigured release fails loudly at startup instead of silently
/// shipping pointed at a developer's laptop:
///
/// ```
/// flutter build appbundle \
///   --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<publishable key>
/// ```
///
/// Debug and profile builds fall back to the local Supabase CLI stack.
class AppEnv {
  static const _definedUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Local CLI development key. Not a secret: it is identical on every machine
  /// running `supabase start`, and it only ever reaches localhost.
  static const _localAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  /// Android emulators reach the host machine via 10.0.2.2.
  static String get _localUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    return 'http://$host:54321';
  }

  static String get supabaseUrl => _definedUrl.isNotEmpty
      ? _definedUrl
      : _localOnly('SUPABASE_URL', _localUrl);

  static String get supabaseAnonKey => _definedKey.isNotEmpty
      ? _definedKey
      : _localOnly('SUPABASE_ANON_KEY', _localAnonKey);

  static String _localOnly(String name, String localValue) {
    if (kReleaseMode) {
      throw StateError(
        'Missing --dart-define=$name. Release builds must point at the hosted '
        'Supabase project; see RELEASE_CHECKLIST.md section B.',
      );
    }
    return localValue;
  }
}

SupabaseClient get supa => Supabase.instance.client;

/// Public URL for a storage object, or null.
String? storageUrl(String bucket, String? path) =>
    path == null ? null : supa.storage.from(bucket).getPublicUrl(path);
