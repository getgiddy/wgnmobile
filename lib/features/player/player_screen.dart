import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/user_state.dart';
import '../../services/audio_player_service.dart';
import '../../services/download_manager.dart';
import '../shell/screen_header.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final np = ref.watch(playerProvider);
    final user = ref.watch(userStateProvider);
    final downloads = ref.watch(downloadsProvider);
    final s = np.sermon;

    if (s == null) {
      return const SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: DetailHeader('Now playing'),
            ),
            EmptyState(['Nothing playing yet.', 'Pick a sermon to begin.']),
          ],
        ),
      );
    }

    final liked = user.likedSermons.contains(s.id);
    final downloaded = downloads.entries.containsKey(s.id);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        children: [
          Row(
            children: [
              BackChevron(onTap: () => Navigator.of(context).maybePop()),
              const Expanded(
                child: Center(child: GoldEyebrow('NOW PLAYING', size: 9.5)),
              ),
              CircleIconButton(
                icon: liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconSize: 16,
                color: liked ? c.gold : c.txt2,
                onTap: () =>
                    ref.read(userStateProvider.notifier).toggleLike(s.id),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const PhPlaceholder(height: 268, radius: 26, label: 'SERMON ARTWORK'),
          const SizedBox(height: 22),
          GoldEyebrow(s.series, size: 9.5),
          const SizedBox(height: 8),
          Text(s.title,
              style: WgnText.serif(26,
                  weight: FontWeight.w500, color: c.txt, height: 1.2)),
          const SizedBox(height: 6),
          Text(s.speaker, style: WgnText.ui(12, color: c.txt2)),
          const SizedBox(height: 22),
          _ProgressBar(progress: np.progress),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(np.position.inSeconds),
                style: WgnText.mono(10.5, color: c.txt3),
              ),
              Text(
                formatDuration(s.durationSecs),
                style: WgnText.mono(10.5, color: c.txt3),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => ref.read(playerProvider.notifier).cycleSpeed(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.line2),
                  ),
                  child: Text(
                    '${np.speed.toStringAsFixed(np.speed % 1 == 0 ? 0 : 2)}×',
                    style: WgnText.mono(
                      11,
                      color: c.txt2,
                    ),
                  ),
                ),
              ),
              _RoundControl(
                label: '15',
                onTap: () =>
                    ref.read(playerProvider.notifier).seekRelative(-15),
              ),
              GestureDetector(
                onTap: () => ref.read(playerProvider.notifier).toggle(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    np.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 30,
                    color: c.onAccent,
                  ),
                ),
              ),
              _RoundControl(
                label: '30',
                onTap: () => ref.read(playerProvider.notifier).seekRelative(30),
              ),
              GestureDetector(
                onTap: () async {
                  final msg = await ref
                      .read(downloadsProvider.notifier)
                      .toggle(
                        s,
                        meta:
                            '${formatDate(s.preachedOn)} · ${formatMins(s.durationSecs)}',
                      );
                  ref.read(toastProvider.notifier).show(msg);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    downloaded ? Icons.download_done : Icons.south,
                    size: 16,
                    color: downloaded ? c.gold : c.txt2,
                  ),
                ),
              ),
            ],
          ),
          if (s.scripture != null) ...[
            const SizedBox(height: 22),
            WgnCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldEyebrow('SCRIPTURE IN THIS SERMON', size: 9.5),
                  const SizedBox(height: 9),
                  Text(
                    s.scripture!,
                    style: WgnText.serif(15, color: c.txt, height: 1.55),
                  ),
                  if (s.scriptureRef != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      s.scriptureRef!,
                      style: WgnText.mono(
                        10.5,
                        color: c.txt3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.line2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: WgnText.ui(11, weight: FontWeight.w600, color: c.txt2),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final p = progress.clamp(0.0, 1.0);
    const thumb = 14.0;
    return SizedBox(
      height: thumb,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: c.line2,
                ),
              ),
              // Filled portion
              Container(
                height: 4,
                width: w * p,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: c.accent,
                ),
              ),
              // Thumb
              Positioned(
                left: (w * p - thumb / 2).clamp(0.0, w - thumb),
                child: Container(
                  width: thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
