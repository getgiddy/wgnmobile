import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/formats.dart';
import '../../core/widgets/ph_placeholder.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../shell/screen_header.dart';

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final updates = ref.watch(updatesProvider).valueOrNull ?? [];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          const DetailHeader('Updates'),
          for (final (i, u) in updates.indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PhPlaceholder(width: 62, height: 62, radius: 13),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.title,
                            style: WgnText.ui(13.5,
                                weight: FontWeight.w700,
                                color: c.txt,
                                height: 1.35)),
                        const SizedBox(height: 5),
                        Text(u.body,
                            style: WgnText.ui(12,
                                color: c.txt2, height: 1.55)),
                        const SizedBox(height: 7),
                        Text(formatDate(u.publishedAt),
                            style: WgnText.mono(10, color: c.txt3)),
                      ],
                    ),
                  ),
                  if (i < 3)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.only(top: 6, left: 8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: c.accent),
                    ),
                ],
              ),
            ),
          if (updates.isEmpty) const EmptyState(['No updates yet.']),
        ],
      ),
    );
  }
}
