import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/user_state.dart';

final _devTabProvider = StateProvider<int>((ref) => 0);

class DevotionsScreen extends ConsumerWidget {
  const DevotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final devotionals = ref.watch(devotionalsProvider).valueOrNull ?? [];
    final user = ref.watch(userStateProvider);
    final tab = ref.watch(_devTabProvider);
    final list = tab == 0
        ? devotionals
        : devotionals
            .where((d) => user.savedDevotionals.contains(d.id))
            .toList();

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
                    const Expanded(child: ScreenTitle('Daily Feast')),
                    if (user.streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: const Color(0xFFD4AF54)
                                  .withValues(alpha: .4)),
                        ),
                        child: Row(
                          children: [
                            Text('${user.streak}',
                                style: WgnText.ui(11,
                                    weight: FontWeight.w700, color: c.gold2)),
                            const SizedBox(width: 6),
                            Text('DAYS',
                                style: WgnText.mono(9,
                                    color: c.gold,
                                    letterSpacing: .7)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedTabs(
                  labels: const ['Latest', 'Saved'],
                  selectedIndex: tab,
                  onChanged: (i) =>
                      ref.read(_devTabProvider.notifier).state = i,
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState([
                    'No saved devotionals yet.',
                    'Tap the bookmark while reading to keep one.'
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final d = list[i];
                      return GestureDetector(
                        onTap: () => context.push('/reader/${d.id}'),
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: c.line))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(d.title,
                                        style: WgnText.serif(19,
                                            weight: FontWeight.w500,
                                            color: c.txt,
                                            height: 1.3)),
                                    const SizedBox(height: 6),
                                    Text(d.verse,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: WgnText.ui(12,
                                            color: c.txt2, height: 1.55)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(formatDayStamp(d.forDate),
                                            style: WgnText.mono(9.5,
                                                color: c.gold)),
                                        const SizedBox(width: 9),
                                        Text(d.tag,
                                            style: WgnText.ui(10.5,
                                                color: c.txt3)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              const PhPlaceholder(
                                  width: 64, height: 64, radius: 13),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
