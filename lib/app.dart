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

/// Navigator the tab bar and mini player are wrapped around. Detail screens are
/// pushed onto this one, so they cover the tabs while the chrome stays put —
/// and, because the tab stack is only covered rather than torn down, every
/// tab's scroll position and state survives underneath.
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// One bottom-tab destination, as its own branch so it keeps its own state.
/// The page transition doesn't matter much here — an [IndexedStack] swaps
/// branches by changing index, with no animation to run — but a plain
/// `builder:` would give the branch's first build the platform default, which
/// under MaterialApp on iOS is a Cupertino push.
StatefulShellBranch _tab(String path, Widget Function() build) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          pageBuilder: (_, state) =>
              NoTransitionPage(key: state.pageKey, child: build()),
        ),
      ],
    );

final _router = GoRouter(
  // Dev aid: `--dart-define=INITIAL_ROUTE=/sermons` opens the app on a
  // specific screen (used for screenshot walks).
  initialLocation:
      const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/'),
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => WgnShell(child: child),
      routes: [
        // The five tabs. Each is a branch with its own navigator, all held
        // alive in an IndexedStack: tapping between them is an index change,
        // not a rebuild, so switching is instant and nothing is re-fetched or
        // scrolled back to the top. Tab taps stay `context.go`.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => navigationShell,
          branches: [
            _tab('/', () => const HomeScreen()),
            _tab('/sermons', () => const SermonsScreen()),
            _tab('/devotions', () => const DevotionsScreen()),
            _tab('/live', () => const LiveScreen()),
            _tab('/more', () => const MoreScreen()),
          ],
        ),
        // Reached by push from more than one tab, so they live beside the
        // branches rather than being duplicated into each one. These keep the
        // platform slide, which is the right idiom for a push.
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
