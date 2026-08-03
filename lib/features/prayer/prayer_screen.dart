import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../shell/screen_header.dart';

final _tagsProvider = StateProvider<Set<String>>((ref) => {'Healing'});
final _anonProvider = StateProvider<bool>((ref) => false);

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _textCtrl.text.trim();
    if (body.isEmpty) {
      ref.read(toastProvider.notifier).show('Write your request first');
      return;
    }
    final uid = supa.auth.currentUser?.id;
    if (uid == null) {
      ref.read(toastProvider.notifier).show('You appear to be offline');
      return;
    }
    setState(() => _sending = true);
    try {
      await supa.from('prayer_requests').insert({
        'user_id': uid,
        'body': body,
        'tags': ref.read(_tagsProvider).toList(),
        'anonymous': ref.read(_anonProvider),
      });
      _textCtrl.clear();
      ref.invalidate(myPrayersProvider);
      ref.read(toastProvider.notifier).show('Received — we are praying');
    } catch (e) {
      ref.read(toastProvider.notifier).show('Could not send — try again');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final config = ref.watch(prayerConfigProvider).valueOrNull;
    final past = ref.watch(myPrayersProvider).valueOrNull ?? [];
    final tags = ref.watch(_tagsProvider);
    final anon = ref.watch(_anonProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        children: [
          const DetailHeader('Prayer requests'),
          const SizedBox(height: 18),
          Text(
            config?.promise ??
                'Our intercessors pray over every request within 24 hours. Nothing you write is published.',
            style: WgnText.serif(16, color: c.txt2, height: 1.6),
          ),
          const SizedBox(height: 24),
          Text('WHAT IS THIS ABOUT?',
              style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6)),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in config?.categories ?? ['Healing', 'Family'])
                PillChip(
                  label: t,
                  selected: tags.contains(t),
                  onTap: () {
                    final next = {...tags};
                    next.contains(t) ? next.remove(t) : next.add(t);
                    ref.read(_tagsProvider.notifier).state = next;
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _textCtrl,
                  maxLines: 5,
                  minLines: 4,
                  style: WgnText.ui(13.5, color: c.txt, height: 1.7),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Write your request here…',
                    hintStyle: WgnText.ui(13.5, color: c.txt3),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Send anonymously',
                            style: WgnText.ui(11.5,
                                weight: FontWeight.w600, color: c.txt2)),
                      ),
                      WgnToggle(
                        value: anon,
                        onChanged: (v) =>
                            ref.read(_anonProvider.notifier).state = v,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          WgnButton(
            label: _sending ? 'Sending…' : 'Send request',
            onTap: _sending ? null : _submit,
          ),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('YOUR PAST REQUESTS',
                style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6)),
            for (final p in past)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.body,
                              style: WgnText.ui(12.5,
                                  weight: FontWeight.w600,
                                  color: c.txt,
                                  height: 1.5)),
                          const SizedBox(height: 5),
                          Text(
                            '${p.createdAt.day} ${['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'][p.createdAt.month - 1]} ${p.createdAt.year}',
                            style: WgnText.mono(10, color: c.txt3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFFD4AF54)
                                .withValues(alpha: .4)),
                      ),
                      child: Text(p.status.toUpperCase(),
                          style: WgnText.mono(9.5, color: c.gold)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
