import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/app_version.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../services/prefs.dart';
import '../shell/menu.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final prefs = ref.watch(prefsProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final menu = buildMenu(ref);

    final name = profile?.fullName ?? 'Guest';
    final since = profile?.createdAt != null
        ? 'Member since ${profile!.createdAt!.year}'
        : 'Tap to set up your profile';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        children: [
          const ScreenTitle('More'),
          const SizedBox(height: 14),
          WgnCard(
            radius: 20,
            padding: const EdgeInsets.all(15),
            onTap: () => context.push('/profile'),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.plum,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile?.initials ?? 'G',
                    style: WgnText.ui(
                      14,
                      weight: FontWeight.w700,
                      color: c.gold2,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: WgnText.ui(
                          15,
                          weight: FontWeight.w700,
                          color: c.txt,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(since, style: WgnText.ui(11, color: c.txt2)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: c.txt3),
              ],
            ),
          ),
          for (final m in menu) ...[
            if (m.head != null)
              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 4),
                child: Text(
                  m.head!,
                  style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => m.go?.call(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        m.label,
                        style: WgnText.ui(
                          13.5,
                          weight: FontWeight.w600,
                          color: c.txt,
                        ),
                      ),
                    ),
                    if (m.hint.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 13),
                        child: Text(
                          m.hint,
                          style: WgnText.ui(
                            11,
                            weight: FontWeight.w600,
                            color: c.gold,
                          ),
                        ),
                      ),
                    Icon(Icons.chevron_right_rounded, size: 18, color: c.txt3),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: WgnText.ui(
                          13.5,
                          weight: FontWeight.w600,
                          color: c.txt,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        prefs.themeMode == ThemeMode.dark
                            ? 'Dark mode'
                            : 'Light mode',
                        style: WgnText.ui(10.5, color: c.txt3),
                      ),
                    ],
                  ),
                ),
                WgnToggle(
                  width: 56,
                  value: prefs.themeMode == ThemeMode.light,
                  onChanged: (_) =>
                      ref.read(prefsProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 26, bottom: 6),
            child: Center(
              child: Text(
                ref.watch(appVersionProvider).valueOrNull ?? '',
                style: WgnText.mono(10, color: c.txt3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
