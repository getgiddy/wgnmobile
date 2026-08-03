import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/utils/app_version.dart';
import '../../core/widgets/toast.dart';
import '../../data/repositories.dart';
import '../shell/screen_header.dart';

/// About + legal. Carries the privacy policy and terms links the stores
/// require to be reachable from inside the app (App Review 5.1.1(i)).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final about = ref.watch(aboutConfigProvider).valueOrNull;

    Future<void> open(String url) async {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ref.read(toastProvider.notifier).show('Could not open the link');
      }
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const DetailHeader('About'),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.gold.withValues(alpha: .55), width: 1.2),
                  ),
                  child: Image.asset(
                    'assets/images/wgn-main-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  about?.churchName ?? 'WordFeast Gospel Network',
                  style: WgnText.display(20, color: c.txt),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (about?.blurb != null) ...[
            const SizedBox(height: 14),
            Text(
              about!.blurb!,
              textAlign: TextAlign.center,
              style: WgnText.serif(15, color: c.txt2, height: 1.6),
            ),
          ],
          const SizedBox(height: 26),
          if (about?.websiteUrl != null)
            _LinkRow('Website', onTap: () => open(about!.websiteUrl!)),
          if (about?.contactEmail != null)
            _LinkRow(
              'Contact us',
              value: about!.contactEmail,
              onTap: () => open('mailto:${about.contactEmail}'),
            ),
          if (about?.privacyPolicyUrl != null)
            _LinkRow('Privacy policy', onTap: () => open(about!.privacyPolicyUrl!)),
          if (about?.termsUrl != null)
            _LinkRow('Terms of service', onTap: () => open(about!.termsUrl!)),
          if (about?.deleteAccountUrl != null)
            _LinkRow(
              'Delete your account',
              onTap: () => open(about!.deleteAccountUrl!),
            ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              ref.watch(appVersionProvider).valueOrNull ?? '',
              style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow(this.label, {this.value, this.onTap});
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
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
                style: WgnText.ui(13, weight: FontWeight.w600, color: c.txt),
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  value!,
                  style: WgnText.ui(11.5, color: c.txt3),
                ),
              ),
            Text('↗', style: WgnText.ui(12, weight: FontWeight.w600, color: c.gold)),
          ],
        ),
      ),
    );
  }
}
