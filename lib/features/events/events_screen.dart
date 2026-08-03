import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/user_state.dart';
import '../shell/screen_header.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final events = ref.watch(eventsProvider).valueOrNull ?? [];
    final user = ref.watch(userStateProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          const DetailHeader('Events'),
          for (final e in events)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: WgnCard(
                radius: 22,
                clip: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhPlaceholder(height: 104, label: 'EVENT FLYER'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(formatEventStamp(e.startsAt),
                                  style: WgnText.mono(9.5,
                                      color: c.gold,
                                      letterSpacing: .9)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        WgnText.ui(10.5, color: c.txt3)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(e.name,
                              style: WgnText.ui(16,
                                  weight: FontWeight.w700,
                                  color: c.txt,
                                  height: 1.3)),
                          const SizedBox(height: 7),
                          Text(e.blurb,
                              style: WgnText.ui(12.5,
                                  color: c.txt2, height: 1.6)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _EventButton(event: e, user: user),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.spotsNote ?? '',
                                    style:
                                        WgnText.ui(10.5, color: c.txt3)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (events.isEmpty)
            const EmptyState(['No upcoming events.', 'Check back soon.']),
        ],
      ),
    );
  }
}

class _EventButton extends ConsumerWidget {
  const _EventButton({required this.event, required this.user});
  final ChurchEvent event;
  final UserState user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final registered = user.registeredEvents.contains(event.id);
    final label = registered
        ? switch (event.ctaType) {
            EventCta.register => 'Registered ✓',
            EventCta.remind => 'Reminder set ✓',
            EventCta.volunteer => 'Signed up ✓',
          }
        : switch (event.ctaType) {
            EventCta.register => 'Register',
            EventCta.remind => 'Remind me',
            EventCta.volunteer => 'Volunteer',
          };

    return GestureDetector(
      onTap: () {
        ref.read(userStateProvider.notifier).toggleRegistration(event.id);
        if (!registered) {
          ref.read(toastProvider.notifier).show(switch (event.ctaType) {
            EventCta.register =>
              'You’re on the list — QR sent to your profile',
            EventCta.remind => 'We’ll remind you before it starts',
            EventCta.volunteer => 'Thank you — the team will reach out',
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: registered ? Colors.transparent : c.accent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.accent),
        ),
        child: Text(label,
            style: WgnText.ui(12,
                weight: FontWeight.w700,
                color: registered ? c.gold : c.onAccent)),
      ),
    );
  }
}
