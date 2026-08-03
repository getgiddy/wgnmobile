import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../services/audio_player_service.dart';
import '../../services/download_manager.dart';
import '../../services/prefs.dart';
import '../shell/screen_header.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final downloads = ref.watch(downloadsProvider);
    final prefs = ref.watch(prefsProvider);
    final sermons = ref.watch(sermonsProvider).valueOrNull ?? [];
    final entries = downloads.entries.values.toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          const DetailHeader('Offline'),
          const SizedBox(height: 16),
          WgnCard(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${downloads.count} sermons on this phone',
                          style: WgnText.ui(13,
                              weight: FontWeight.w700, color: c.txt)),
                      const SizedBox(height: 3),
                      Text(
                        '${formatSize(downloads.totalBytes)} used · Wi-Fi only downloads',
                        style: WgnText.ui(10.5, color: c.txt3),
                      ),
                    ],
                  ),
                ),
                WgnToggle(
                  value: prefs.wifiOnly,
                  onChanged: (_) =>
                      ref.read(prefsProvider.notifier).toggleWifiOnly(),
                ),
              ],
            ),
          ),
          for (final e in entries)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final sermon = sermons
                          .where((s) => s.id == e.sermonId)
                          .firstOrNull;
                      if (sermon != null) {
                        ref
                            .read(playerProvider.notifier)
                            .playSermon(sermon);
                        context.push('/player');
                      }
                    },
                    child:
                        const PhPlaceholder(width: 56, height: 56, radius: 13),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WgnText.ui(13,
                                weight: FontWeight.w700,
                                color: c.txt,
                                height: 1.35)),
                        const SizedBox(height: 4),
                        Text(
                            e.meta.isNotEmpty
                                ? e.meta
                                : '${e.speaker} · ${formatSize(e.sizeBytes)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: WgnText.ui(10.5, color: c.txt3)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(downloadsProvider.notifier)
                          .remove(e.sermonId);
                      ref
                          .read(toastProvider.notifier)
                          .show('Removed from offline');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: c.line2),
                      ),
                      child: Text('REMOVE',
                          style: WgnText.mono(10, color: c.txt3)),
                    ),
                  ),
                ],
              ),
            ),
          if (entries.isEmpty)
            const EmptyState([
              'Nothing downloaded yet.',
              'Tap ↓ on any sermon to keep it offline.'
            ]),
        ],
      ),
    );
  }
}
