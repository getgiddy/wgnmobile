import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/supabase_client.dart';
import 'services/audio_player_service.dart';
import 'services/prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PrefsNotifier.init();
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabaseAnonKey,
  );
  // A stored session can outlive the user it points at: the account was
  // deleted on another device, or the database was reset in development.
  // gotrue restores it happily and every later call then fails with "Auth
  // session missing!", with no way back. Check it once and discard it if the
  // user is gone.
  if (supa.auth.currentSession != null) {
    try {
      await supa.auth.getUser();
    } on AuthException catch (e) {
      debugPrint('stored session no longer valid ($e) — starting fresh');
      await supa.auth.signOut();
    } catch (e) {
      // Offline. Keep the session; it may well still be good.
      debugPrint('could not verify stored session (offline?): $e');
    }
  }
  // Guest-first: everyone gets an (anonymous) session so likes, streaks and
  // progress sync from day one and survive a later account upgrade. This can
  // legitimately fail — anonymous sign-ins may be disabled on the project, or
  // the device may be offline — so the app has to stay usable without one.
  if (supa.auth.currentSession == null) {
    try {
      await supa.auth.signInAnonymously();
    } catch (e) {
      debugPrint('anonymous sign-in failed: $e');
    }
  }
  await PlayerController.initAudio();
  runApp(const ProviderScope(child: WgnApp()));
}
