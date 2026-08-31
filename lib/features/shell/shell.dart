import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../services/audio_player_service.dart';

const _tabs = [
  ('/', 'Home'),
  ('/sermons', 'Sermons'),
  ('/devotions', 'Devotions'),
  ('/live', 'Live'),
  ('/more', 'More'),
];

class WgnShell extends ConsumerWidget {
  const WgnShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final location = GoRouterState.of(context).uri.path;
    // Only *whether* a sermon is loaded decides if the mini player shows, but
    // the player's position stream ticks several times a second. Watching the
    // whole state rebuilt the shell — and the nav bar with it — on every tick,
    // including every frame of a route transition. Narrow it to the bool.
    final hasSermon = ref.watch(playerProvider.select((s) => s.sermon != null));
    final showMini = hasSermon && location != '/player';

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: child),
              // The mini player legitimately repaints on every position tick.
              // Without a boundary that dirties the whole shell layer, so the
              // nav bar re-rasters alongside it.
              if (showMini) const RepaintBoundary(child: _MiniPlayer()),
              _NavBar(location: location),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 104,
            child: const ToastHost(),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: c.nav,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (final (path, label) in _tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go(path),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: WgnText.ui(11,
                            weight: FontWeight.w700,
                            color: location == path ? c.gold2 : c.txt3),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1),
                          color: location == path
                              ? c.accent
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniPlayer extends ConsumerWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final np = ref.watch(playerProvider);
    final s = np.sermon!;
    return GestureDetector(
      onTap: () => context.push('/player'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Stack(
          children: [
            // Progress underline
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: np.progress,
                  child: Container(height: 2, color: c.accent),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  const PhPlaceholder(width: 38, height: 38, radius: 10),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WgnText.ui(11.5,
                              weight: FontWeight.w700, color: c.txt),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatDuration(np.position.inSeconds)} / ${formatDuration(s.durationSecs)}',
                          style: WgnText.mono(9.5, color: c.txt3),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(playerProvider.notifier).toggle(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: c.accent),
                      alignment: Alignment.center,
                      child: Icon(
                        np.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                        color: c.onAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
