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
  // Guest-first: everyone gets an (anonymous) session so likes, streaks and
  // progress sync from day one and survive a later account upgrade.
  if (supa.auth.currentSession == null) {
    try {
      await supa.auth.signInAnonymously();
    } catch (e) {
      debugPrint('anonymous sign-in failed (offline?): $e');
    }
  }
  await PlayerController.initAudio();
  runApp(const ProviderScope(child: WgnApp()));
}
