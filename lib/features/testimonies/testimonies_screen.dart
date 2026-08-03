import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../../data/user_state.dart';
import '../shell/screen_header.dart';

class TestimoniesScreen extends ConsumerWidget {
  const TestimoniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final feed = ref.watch(testimoniesProvider).valueOrNull ?? [];
    final user = ref.watch(userStateProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          const DetailHeader('Testimonies'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showShareSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFD4AF54).withValues(alpha: .5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: c.accent),
                    alignment: Alignment.center,
                    child: Text('+',
                        style: WgnText.ui(15,
                            weight: FontWeight.w700, color: c.onAccent)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share what God did',
                          style: WgnText.ui(13,
                              weight: FontWeight.w700, color: c.txt)),
                      const SizedBox(height: 2),
                      Text('Reviewed before it appears in the feed',
                          style: WgnText.ui(10.5, color: c.txt2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          for (final t in feed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: WgnCard(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: c.plum),
                          alignment: Alignment.center,
                          child: Text(t.initials,
                              style: WgnText.ui(10,
                                  weight: FontWeight.w700, color: c.gold2)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.displayName,
                                  style: WgnText.ui(12.5,
                                      weight: FontWeight.w700,
                                      color: c.txt)),
                              const SizedBox(height: 2),
                              Text(t.locationTag,
                                  style:
                                      WgnText.mono(10, color: c.txt3)),
                            ],
                          ),
                        ),
                        Text(t.category,
                            style: WgnText.mono(9.5, color: c.gold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(t.body,
                        style: WgnText.serif(15, color: c.txt, height: 1.6)),
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.only(top: 13),
                      decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line))),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => ref
                                .read(userStateProvider.notifier)
                                .toggleAmen(t.id),
                            child: Text(
                              'Amen · ${t.amensBase + t.amens + (user.amenedTestimonies.contains(t.id) ? 1 : 0)}',
                              style: WgnText.ui(11.5,
                                  weight: FontWeight.w700,
                                  color: user.amenedTestimonies.contains(t.id)
                                      ? c.gold
                                      : c.txt2),
                            ),
                          ),
                          const SizedBox(width: 18),
                          GestureDetector(
                            onTap: () => ref
                                .read(toastProvider.notifier)
                                .show('Sharing comes with the next build'),
                            child: Text('Share',
                                style: WgnText.ui(11.5,
                                    weight: FontWeight.w600,
                                    color: c.txt3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(sheetCtx).padding.bottom + 24),
          decoration: BoxDecoration(
            color: c.nav,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: c.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share what God did',
                  style: WgnText.display(19, color: c.txt)),
              const SizedBox(height: 6),
              Text('The media team reviews every testimony before it appears.',
                  style: WgnText.ui(11.5, color: c.txt2, height: 1.5)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: c.surf,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.line),
                ),
                child: TextField(
                  controller: ctrl,
                  maxLines: 6,
                  minLines: 4,
                  autofocus: true,
                  style: WgnText.ui(13.5, color: c.txt, height: 1.7),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Tell us what happened…',
                    hintStyle: WgnText.ui(13.5, color: c.txt3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              WgnButton(
                label: 'Send for review',
                onTap: () async {
                  final body = ctrl.text.trim();
                  if (body.isEmpty) return;
                  Navigator.of(sheetCtx).pop();
                  final uid = supa.auth.currentUser?.id;
                  if (uid == null) return;
                  final profile =
                      await ref.read(profileProvider.future);
                  final name = profile?.fullName ?? 'A member';
                  try {
                    await supa.from('testimonies').insert({
                      'user_id': uid,
                      'display_name': name,
                      'initials': profile?.initials ?? 'WM',
                      'location_tag': 'MEMBER',
                      'category': 'TESTIMONY',
                      'body': body,
                      'approved': false,
                    });
                    ref
                        .read(toastProvider.notifier)
                        .show('Received — the team will review it');
                  } catch (_) {
                    ref
                        .read(toastProvider.notifier)
                        .show('Could not send — try again');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
