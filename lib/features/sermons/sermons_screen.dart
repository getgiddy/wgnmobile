import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/user_state.dart';
import '../../services/audio_player_service.dart';
import '../../services/download_manager.dart';

final _tabProvider = StateProvider<int>((ref) => 0);
final _queryProvider = StateProvider<String>((ref) => '');
final _sortProvider = StateProvider<int>((ref) => 0);

const _sortNames = ['NEWEST', 'OLDEST', 'A–Z'];

/// Filter + sort logic (kept pure for unit testing).
List<Sermon> filterSermons(
  List<Sermon> all,
  SermonKind kind,
  String query,
  int sort,
) {
  var list = query.trim().isEmpty
      ? all.where((s) => s.kind == kind).toList()
      : all
            .where(
              (s) => '${s.title} ${s.series} ${s.speaker}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
            )
            .toList();
  switch (sort) {
    case 1:
      list = list.reversed.toList();
    case 2:
      list.sort((a, b) => a.title.compareTo(b.title));
  }
  return list;
}

class SermonsScreen extends ConsumerWidget {
  const SermonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final all = ref.watch(sermonsProvider).valueOrNull ?? [];
    final tab = ref.watch(_tabProvider);
    final query = ref.watch(_queryProvider);
    final sort = ref.watch(_sortProvider);
    final dlCount = ref.watch(downloadsProvider).count;
    final kind = SermonKind.values[tab];
    final list = filterSermons(all, kind, query, sort);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: ScreenTitle('Sermons')),
                    GestureDetector(
                      onTap: () => context.push('/downloads'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF54,
                            ).withValues(alpha: .4),
                          ),
                        ),
                        child: Text(
                          '$dlCount offline',
                          style: WgnText.ui(
                            11,
                            weight: FontWeight.w600,
                            color: c.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedTabs(
                  labels: const ['Audio', 'Video', 'Series'],
                  selectedIndex: tab,
                  onChanged: (i) => ref.read(_tabProvider.notifier).state = i,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.surf,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 16, color: c.txt3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (v) =>
                              ref.read(_queryProvider.notifier).state = v,
                          style: WgnText.ui(12.5, color: c.txt),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            hintText: 'Search sermons, series, scripture',
                            hintStyle: WgnText.ui(12.5, color: c.txt3),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(_sortProvider.notifier).state =
                            (sort + 1) % 3,
                        child: Text(
                          _sortNames[sort],
                          style: WgnText.mono(
                            9.5,
                            color: c.gold,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyState([
                    'Nothing matches “$query”.',
                    'Try a series name or a book of the Bible.',
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    itemCount: list.length,
                    itemBuilder: (context, i) => SermonRow(sermon: list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Sermon list row with download / like / overflow actions.
class SermonRow extends ConsumerWidget {
  const SermonRow({super.key, required this.sermon});
  final Sermon sermon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final user = ref.watch(userStateProvider);
    final downloads = ref.watch(downloadsProvider);
    final liked = user.likedSermons.contains(sermon.id);
    final downloaded = downloads.entries.containsKey(sermon.id);
    final downloading = downloads.inProgress.containsKey(sermon.id);
    final meta =
        '${formatDate(sermon.preachedOn)} · ${formatMins(sermon.durationSecs)}'
        '${sermon.sizeBytes != null ? ' · ${formatSize(sermon.sizeBytes)}' : ''}';

    void play() {
      if (sermon.kind == SermonKind.video) {
        ref.read(toastProvider.notifier).show('Video opens on the Live tab');
        return;
      }
      ref.read(playerProvider.notifier).playSermon(sermon);
      context.push('/player');
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: play,
            child: const PhPlaceholder(width: 62, height: 62, radius: 13),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: play,
                  child: Text(
                    sermon.title,
                    style: WgnText.ui(
                      13.5,
                      weight: FontWeight.w700,
                      color: c.txt,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(meta, style: WgnText.ui(10.5, color: c.txt3)),
                const SizedBox(height: 9),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final msg = await ref
                            .read(downloadsProvider.notifier)
                            .toggle(sermon, meta: meta);
                        ref.read(toastProvider.notifier).show(msg);
                      },
                      child: Text(
                        downloading
                            ? '… ${((downloads.inProgress[sermon.id] ?? 0) * 100).round()}%'
                            : (downloaded ? '✓ OFFLINE' : '↓ DOWNLOAD'),
                        style: WgnText.mono(
                          10.5,
                          color: downloaded || downloading ? c.gold : c.txt3,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    // const SizedBox(width: 16),
                    // GestureDetector(
                    //   onTap: () => ref
                    //       .read(userStateProvider.notifier)
                    //       .toggleLike(sermon.id),
                    //   child: Icon(
                    //     liked
                    //         ? Icons.favorite_rounded
                    //         : Icons.favorite_border_rounded,
                    //     size: 16,
                    //     color: liked ? c.gold : c.txt3,
                    //   ),
                    // ),
                    // const SizedBox(width: 16),
                    // Icon(Icons.more_horiz_rounded, size: 16, color: c.txt3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
