import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../shell/screen_header.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final articles = ref.watch(journalProvider).valueOrNull ?? [];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          const DetailHeader('The Journal'),
          const SizedBox(height: 16),
          Text(
            'Longer writing from the house — teaching notes, letters and the monthly newsletter.',
            style: WgnText.serif(16, color: c.txt2, height: 1.6),
          ),
          for (final j in articles)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: WgnCard(
                radius: 20,
                clip: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhPlaceholder(height: 112),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ISSUE ${j.issueNo} · ${j.readMins} MIN READ',
                              style: WgnText.mono(9.5,
                                  color: c.gold, letterSpacing: 1.3)),
                          const SizedBox(height: 8),
                          Text(j.title,
                              style: WgnText.ui(15.5,
                                  weight: FontWeight.w700,
                                  color: c.txt,
                                  height: 1.32)),
                          const SizedBox(height: 7),
                          Text(j.dek,
                              style: WgnText.ui(12.5,
                                  color: c.txt2, height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (articles.isEmpty)
            const EmptyState(['No journal issues yet.']),
        ],
      ),
    );
  }
}
