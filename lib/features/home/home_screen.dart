import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/user_state.dart';
import '../../services/audio_player_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final sermons = ref.watch(sermonsProvider).valueOrNull ?? [];
    final devotionals = ref.watch(devotionalsProvider).valueOrNull ?? [];
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final testimonies = ref.watch(testimoniesProvider).valueOrNull ?? [];
    final user = ref.watch(userStateProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final np = ref.watch(playerProvider);

    final audioSermons = sermons
        .where((s) => s.kind == SermonKind.audio)
        .take(5)
        .toList();
    // Continue-listening: current player sermon, else last one with progress.
    Sermon? continueSermon = np.sermon;
    if (continueSermon == null &&
        user.playback.isNotEmpty &&
        sermons.isNotEmpty) {
      continueSermon = sermons
          .where((s) => user.playback.containsKey(s.id))
          .fold<Sermon?>(null, (best, s) => best ?? s);
    }
    continueSermon ??= audioSermons.isNotEmpty ? audioSermons.first : null;
    final today = devotionals.isNotEmpty ? devotionals.first : null;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                  style: WgnText.ui(12, color: c.txt3),
                ),
                const SizedBox(height: 4),
                Text(
                  _greeting(profile?.fullName),
                  style: WgnText.display(22, color: c.txt, height: 1.15),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              children: [
                if (continueSermon != null) _ContinueRow(sermon: continueSermon),
                if (today != null) ...[
                  const SizedBox(height: 26),
                  _DailyFeastCard(devotional: today),
                ],
                if (audioSermons.isNotEmpty) ...[
                  const SizedBox(height: 34),
                  SectionHeader(
                    'Recent sermons',
                    action: 'All',
                    onAction: () => context.go('/sermons'),
                  ),
                  const SizedBox(height: 14),
                  for (final s in audioSermons) _RecentSermonRow(sermon: s),
                ],
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  SectionHeader(
                    'This week',
                    action: 'All events',
                    onAction: () => context.push('/events'),
                  ),
                  const SizedBox(height: 14),
                  for (final e in events.take(2)) _EventRow(event: e),
                ],
                if (testimonies.isNotEmpty)
                  _TopTestimony(testimony: testimonies.first),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String? name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final first = name?.trim().split(' ').first;
    return first == null || first.isEmpty ? part : '$part, $first';
  }
}

/// Continue-listening row: artwork, title, hairline progress, play button.
class _ContinueRow extends ConsumerWidget {
  const _ContinueRow({required this.sermon});
  final Sermon sermon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final np = ref.watch(playerProvider);
    final user = ref.watch(userStateProvider);
    final isCurrent = np.sermon?.id == sermon.id;
    final progress = isCurrent
        ? np.progress
        : ((user.playback[sermon.id] ?? 0) / sermon.durationSecs).clamp(
            0.0,
            1.0,
          );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(playerProvider.notifier).playSermon(sermon);
        context.push('/player');
      },
      child: Row(
        children: [
          const PhPlaceholder(width: 64, height: 64, radius: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUE',
                  style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.4),
                ),
                const SizedBox(height: 5),
                Text(
                  sermon.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WgnText.ui(
                    14.5,
                    weight: FontWeight.w700,
                    color: c.txt,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: c.line2,
                    valueColor: AlwaysStoppedAnimation(c.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {
              if (isCurrent) {
                ref.read(playerProvider.notifier).toggle();
              } else {
                ref.read(playerProvider.notifier).playSermon(sermon);
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent),
              alignment: Alignment.center,
              child: Icon(
                isCurrent && np.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 21,
                color: c.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFeastCard extends ConsumerWidget {
  const _DailyFeastCard({required this.devotional});
  final Devotional devotional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final user = ref.watch(userStateProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: GoldEyebrow('DAILY FEAST')),
              if (user.streak > 0)
                Text(
                  'Day ${user.streak}',
                  style: WgnText.ui(
                    10.5,
                    weight: FontWeight.w600,
                    color: c.txt3,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            devotional.title,
            style: WgnText.serif(
              27,
              weight: FontWeight.w500,
              color: c.txt,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            devotional.verse,
            style: WgnText.ui(
              13.5,
              weight: FontWeight.w400,
              color: c.txt2,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            devotional.verseRef,
            style: WgnText.mono(11, color: c.gold, letterSpacing: .66),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/reader/${devotional.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Read today',
                    style: WgnText.ui(
                      12,
                      weight: FontWeight.w700,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _WeekDots(readDates: user.readDates),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seven 8px dots — filled for days already read, ringed for today.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.readDates});
  final Set<String> readDates;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final today = DateTime.now();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 6; i >= 0; i--)
          Builder(
            builder: (context) {
              final day = today.subtract(Duration(days: i));
              final key =
                  '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final done = readDates.contains(key);
              final isToday = i == 0;
              return Padding(
                padding: EdgeInsets.only(left: i == 6 ? 0 : 7),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? c.accent : Colors.transparent,
                    border: Border.all(
                      color: done || isToday ? c.accent : c.line2,
                      width: 1.3,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _RecentSermonRow extends ConsumerWidget {
  const _RecentSermonRow({required this.sermon});
  final Sermon sermon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(playerProvider.notifier).playSermon(sermon);
        context.push('/player');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            const PhPlaceholder(width: 52, height: 52, radius: 13),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WgnText.ui(
                      13.5,
                      weight: FontWeight.w700,
                      color: c.txt,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sermon.speaker,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WgnText.ui(11, color: c.txt3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatMins(sermon.durationSecs),
              style: WgnText.mono(10, color: c.txt3),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final ChurchEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/events'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    const [
                      'MON',
                      'TUE',
                      'WED',
                      'THU',
                      'FRI',
                      'SAT',
                      'SUN',
                    ][event.startsAt.weekday - 1],
                    style: WgnText.mono(9, color: c.txt3, letterSpacing: .9),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    event.startsAt.day.toString().padLeft(2, '0'),
                    style: WgnText.ui(19, weight: FontWeight.w800, color: c.txt),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WgnText.ui(
                      13.5,
                      weight: FontWeight.w700,
                      color: c.txt,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatEventWhen(event.startsAt, event.location),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WgnText.ui(11, color: c.txt3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(switch (event.ctaType) {
              EventCta.register => 'Register',
              EventCta.remind => 'Remind me',
              EventCta.volunteer => 'Volunteer',
            }, style: WgnText.ui(11, weight: FontWeight.w600, color: c.gold)),
          ],
        ),
      ),
    );
  }
}

/// Pull-quote teaser linking through to the testimonies feed.
class _TopTestimony extends StatelessWidget {
  const _TopTestimony({required this.testimony});
  final Testimony testimony;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/testimonies'),
      child: Container(
        margin: const EdgeInsets.only(top: 26),
        padding: const EdgeInsets.only(top: 22),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('“', style: WgnText.serif(34, color: c.gold, height: 1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testimony.body.replaceAll(RegExp(r'[“”]'), ''),
                    style: WgnText.serif(16, color: c.txt, height: 1.55),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${testimony.displayName} · Testimonies',
                    style: WgnText.ui(
                      11,
                      weight: FontWeight.w600,
                      color: c.txt3,
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
