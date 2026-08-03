import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/wgn_theme.dart';
import 'features/about/about_screen.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/devotions/devotions_screen.dart';
import 'features/events/events_screen.dart';
import 'features/giving/giving_screen.dart';
import 'features/home/home_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/live/live_screen.dart';
import 'features/more/more_screen.dart';
import 'features/player/player_screen.dart';
import 'features/prayer/prayer_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reader/reader_screen.dart';
import 'features/sermons/sermons_screen.dart';
import 'features/shell/shell.dart';
import 'features/testimonies/testimonies_screen.dart';
import 'features/updates/updates_screen.dart';
import 'services/prefs.dart';

final _router = GoRouter(
  // Dev aid: `--dart-define=INITIAL_ROUTE=/sermons` opens the app on a
  // specific screen (used for screenshot walks).
  initialLocation:
      const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/'),
  routes: [
    ShellRoute(
      builder: (context, state, child) => WgnShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/sermons', builder: (_, _) => const SermonsScreen()),
        GoRoute(path: '/devotions', builder: (_, _) => const DevotionsScreen()),
        GoRoute(path: '/live', builder: (_, _) => const LiveScreen()),
        GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
        GoRoute(path: '/player', builder: (_, _) => const PlayerScreen()),
        GoRoute(
          path: '/reader/:id',
          builder: (_, state) =>
              ReaderScreen(devotionalId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(path: '/giving', builder: (_, _) => const GivingScreen()),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
        GoRoute(path: '/prayer', builder: (_, _) => const PrayerScreen()),
        GoRoute(
            path: '/testimonies', builder: (_, _) => const TestimoniesScreen()),
        GoRoute(path: '/journal', builder: (_, _) => const JournalScreen()),
        GoRoute(path: '/updates', builder: (_, _) => const UpdatesScreen()),
        GoRoute(path: '/downloads', builder: (_, _) => const DownloadsScreen()),
        GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      ],
    ),
  ],
);

class WgnApp extends ConsumerWidget {
  const WgnApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    return MaterialApp.router(
      title: 'WGN Mobile',
      debugShowCheckedModeBanner: false,
      themeMode: prefs.themeMode,
      theme: buildWgnTheme(Brightness.light),
      darkTheme: buildWgnTheme(Brightness.dark),
      routerConfig: _router,
    );
  }
}
