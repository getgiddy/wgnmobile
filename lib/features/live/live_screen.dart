import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  YoutubePlayerController? _yt;
  String? _loadedId;

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }

  void _ensurePlayer(LiveStatus live) {
    if (!live.isLive || live.youtubeId.isEmpty) return;
    if (_loadedId == live.youtubeId) return;
    _loadedId = live.youtubeId;
    _yt?.close();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: live.youtubeId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final liveAsync = ref.watch(liveStatusProvider);
    final platforms = ref.watch(platformsProvider).valueOrNull ?? [];
    final live = liveAsync.valueOrNull;
    if (live != null) _ensurePlayer(live);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        children: [
          const ScreenTitle('Live'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: (live?.isLive ?? false) && _yt != null
                        ? YoutubePlayer(controller: _yt!)
                        : PhPlaceholder(
                            label: live == null
                                ? 'CONNECTING…'
                                : 'NO LIVE SERVICE RIGHT NOW',
                          ),
                  ),
                  if (live?.isLive ?? false) ...[
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB80A060E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0483B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ON AIR',
                              style: WgnText.mono(
                                9.5,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (live?.watching != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xB80A060E),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${live!.watching} watching',
                            style: WgnText.mono(
                              9.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (live != null && live.isLive) ...[
            const SizedBox(height: 14),
            Text(
              '${live.serviceName} ${live.serviceNo} — ${live.title}',
              style: WgnText.ui(
                16,
                weight: FontWeight.w700,
                color: c.txt,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${live.speaker}${live.startedAt != null ? ' · started ${DateTime.now().difference(live.startedAt!).inMinutes} min ago' : ''}',
              style: WgnText.ui(11.5, color: c.txt2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref
                        .read(toastProvider.notifier)
                        .show(
                          'Audio-only mode — keep listening with the screen off',
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Audio only',
                        style: WgnText.ui(
                          12,
                          weight: FontWeight.w700,
                          color: c.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/giving'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Give now',
                        style: WgnText.ui(
                          12,
                          weight: FontWeight.w700,
                          color: c.txt,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          Container(
            height: 1,
            color: c.line,
            margin: const EdgeInsets.only(top: 20, bottom: 16),
          ),
          Text(
            'BROADCAST SCHEDULE',
            style: WgnText.mono(10, color: c.gold, letterSpacing: 1.6),
          ),
          for (final p in platforms)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      p.kind,
                      style: WgnText.mono(
                        9,
                        color: c.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: WgnText.ui(
                            12.5,
                            weight: FontWeight.w700,
                            color: c.txt,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.scheduleText,
                          style: WgnText.ui(10.5, color: c.txt3),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.north_east, size: 16, color: c.txt3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
