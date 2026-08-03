import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../../data/user_state.dart';
import '../../services/download_manager.dart';
import '../auth/auth_sheet.dart';
import '../shell/screen_header.dart';
import 'delete_account_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(userStateProvider);
    final dlCount = ref.watch(downloadsProvider).count;
    final isAnon = supa.auth.currentUser?.isAnonymous ?? true;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        children: [
          const DetailHeader('Profile'),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.plum,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile?.initials ?? 'G',
                    style: WgnText.ui(
                      24,
                      weight: FontWeight.w700,
                      color: c.gold2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.fullName ?? 'Guest',
                  style: WgnText.ui(18, weight: FontWeight.w800, color: c.txt),
                ),
                const SizedBox(height: 4),
                Text(
                  isAnon ? 'Browsing as a guest' : (profile?.email ?? ''),
                  style: WgnText.ui(11.5, color: c.txt2),
                ),
              ],
            ),
          ),
          if (isAnon) ...[
            const SizedBox(height: 16),
            WgnButton(
              label: 'Create account · keep your streaks',
              padding: const EdgeInsets.symmetric(vertical: 13),
              fontSize: 12.5,
              onTap: () => showAuthSheet(context),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCard(value: '${user.streak}', label: 'Feast streak'),
              const SizedBox(width: 9),
              _StatCard(value: '$dlCount', label: 'Offline'),
              const SizedBox(width: 9),
              _StatCard(value: '${user.likedSermons.length}', label: 'Saved'),
            ],
          ),
          const SizedBox(height: 18),
          WgnCard(
            radius: 22,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  'Show this at the welcome desk for quick check-in.',
                  textAlign: TextAlign.center,
                  style: WgnText.ui(11.5, color: c.txt2, height: 1.6),
                ),
                Container(
                  width: 168,
                  height: 168,
                  margin: const EdgeInsets.only(top: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: profile?.memberCode ?? 'WGN-GUEST',
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1E1425),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E1425),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.memberCode ?? 'WGN-GUEST',
                  style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ProfileRow(
            'Personal details',
            value: profile?.fullName ?? 'Add your name',
            onTap: () => showAuthSheet(context),
          ),
          _ProfileRow('Home branch', value: profile?.branch ?? 'Not set'),
          _ProfileRow(
            'Giving history',
            value: 'View',
            onTap: () => ref
                .read(toastProvider.notifier)
                .show('Giving history arrives with online giving'),
          ),
          _ProfileRow('Notifications', value: 'On'),
          if (!isAnon)
            _ProfileRow(
              'Sign out',
              onTap: () async {
                await supa.auth.signOut();
                try {
                  await supa.auth.signInAnonymously();
                } on AuthException catch (_) {}
                ref.invalidate(profileProvider);
                await ref.read(userStateProvider.notifier).reload();
                ref.read(toastProvider.notifier).show('Signed out');
              },
            ),
          _ProfileRow(
            'Delete account',
            danger: true,
            onTap: () => showDeleteAccountSheet(context),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: WgnText.ui(18, weight: FontWeight.w800, color: c.gold2),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: WgnText.ui(9.5, weight: FontWeight.w600, color: c.txt3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow(
    this.label, {
    this.value = '',
    this.onTap,
    this.danger = false,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final labelColor = danger ? const Color(0xFFE0483B) : c.txt;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: WgnText.ui(
                  13,
                  weight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 13),
                child: Text(value, style: WgnText.ui(11.5, color: c.txt3)),
              ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.txt3),
          ],
        ),
      ),
    );
  }
}
