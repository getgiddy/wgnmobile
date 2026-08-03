import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/user_state.dart';

class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.devotionalId});
  final int devotionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final devotionals = ref.watch(devotionalsProvider).valueOrNull ?? [];
    final user = ref.watch(userStateProvider);
    final d =
        devotionals.where((x) => x.id == devotionalId).firstOrNull ??
        (devotionals.isNotEmpty ? devotionals.first : null);

    if (d == null) {
      return const SafeArea(child: EmptyState(['Loading today’s devotional…']));
    }

    final saved = user.savedDevotionals.contains(d.id);
    final isToday =
        d.forDate.day == DateTime.now().day &&
        d.forDate.month == DateTime.now().month &&
        d.forDate.year == DateTime.now().year;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        children: [
          Row(
            children: [
              BackChevron(onTap: () => Navigator.of(context).maybePop()),
              const Spacer(),
              CircleIconButton(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_add_outlined,
                iconSize: 16,
                color: saved ? c.gold : c.txt2,
                onTap: () {
                  ref.read(userStateProvider.notifier).toggleSaved(d.id);
                  ref
                      .read(toastProvider.notifier)
                      .show(saved ? 'Removed' : 'Saved to your devotionals');
                },
              ),
              const SizedBox(width: 9),
              CircleIconButton(
                icon: Icons.ios_share_rounded,
                iconSize: 15,
                onTap: () => ref
                    .read(toastProvider.notifier)
                    .show('Sharing comes with the next build'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GoldEyebrow(
            '${formatDayStamp(d.forDate)}${user.streak > 0 ? ' · DAY ${user.streak}' : ''}',
            size: 9.5,
          ),
          const SizedBox(height: 10),
          Text(d.title,
              style: WgnText.serif(32,
                  weight: FontWeight.w500, color: c.txt, height: 1.14)),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.accent, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.verse,
                  style: WgnText.serif(
                    16,
                    color: c.txt,
                    height: 1.55,
                    style: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  d.verseRef,
                  style: WgnText.mono(
                    10.5,
                    color: c.gold,
                  ),
                ),
              ],
            ),
          ),
          for (final p in d.body)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                p,
                style: WgnText.ui(
                  14.5,
                  weight: FontWeight.w400,
                  color: c.txt2,
                  height: 1.75,
                ),
              ),
            ),
          if (d.prayer != null)
            Container(
              margin: const EdgeInsets.only(top: 22),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldEyebrow('PRAYER', size: 9.5),
                  const SizedBox(height: 8),
                  Text(
                    d.prayer!,
                    style: WgnText.serif(15, color: c.txt, height: 1.6),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          WgnButton(
            label: !isToday
                ? 'This was ${formatDayStamp(d.forDate)}'
                : user.readToday
                ? 'Marked for today ✓'
                : 'Mark today as read',
            padding: const EdgeInsets.symmetric(vertical: 15),
            fontSize: 13,
            onTap: !isToday
                ? null
                : () {
                    final marked = ref
                        .read(userStateProvider.notifier)
                        .markTodayRead();
                    final streak = ref.read(userStateProvider).streak;
                    ref
                        .read(toastProvider.notifier)
                        .show(
                          marked
                              ? 'Day marked — streak $streak'
                              : 'Already marked for today',
                        );
                  },
          ),
        ],
      ),
    );
  }
}
