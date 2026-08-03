import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';

/// Bottom sheet with the church's bank / mobile-money details, from
/// app_config. Shown from the Giving screen and the More menu.
void showGivingDetailsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GivingDetailsSheet(),
  );
}

class _GivingDetailsSheet extends ConsumerWidget {
  const _GivingDetailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.wgn;
    final giving = ref.watch(givingConfigProvider).valueOrNull;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: BoxDecoration(
        color: c.nav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: c.line),
      ),
      child: giving == null
          ? const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.line2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Giving details',
                    style: WgnText.display(19, color: c.txt)),
                const SizedBox(height: 16),
                const GoldEyebrow('BANK TRANSFER'),
                const SizedBox(height: 10),
                _DetailRow('Bank', giving.bank['bank_name'] as String? ?? ''),
                _DetailRow(
                    'Account name', giving.bank['account_name'] as String? ?? ''),
                _DetailRow('Account number',
                    giving.bank['account_number'] as String? ?? ''),
                const SizedBox(height: 16),
                const GoldEyebrow('MOBILE MONEY'),
                const SizedBox(height: 10),
                _DetailRow(
                    'Provider', giving.mobileMoney['provider'] as String? ?? ''),
                _DetailRow(
                    'Number', giving.mobileMoney['number'] as String? ?? ''),
                _DetailRow('Name', giving.mobileMoney['name'] as String? ?? ''),
                const SizedBox(height: 14),
                Text(giving.note,
                    style: WgnText.ui(11, color: c.txt3, height: 1.6)),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: WgnText.ui(12, color: c.txt2))),
          Text(value,
              style: WgnText.ui(12.5, weight: FontWeight.w700, color: c.txt)),
        ],
      ),
    );
  }
}
