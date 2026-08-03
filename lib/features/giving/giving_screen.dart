import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../shell/screen_header.dart';
import 'giving_details_sheet.dart';

final _purposeProvider = StateProvider<String>((ref) => 'Offering');
final _amountProvider = StateProvider<String>((ref) => '');
final _railProvider = StateProvider<String>((ref) => 'manual');

class GivingScreen extends ConsumerStatefulWidget {
  const GivingScreen({super.key});

  @override
  ConsumerState<GivingScreen> createState() => _GivingScreenState();
}

class _GivingScreenState extends ConsumerState<GivingScreen> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: ref.read(_amountProvider));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final giving = ref.watch(givingConfigProvider).valueOrNull;
    final purpose = ref.watch(_purposeProvider);
    final amount = ref.watch(_amountProvider);
    final rail = ref.watch(_railProvider);

    final rails = [
      (
        'paystack',
        'Paystack',
        'Card, bank transfer, USSD — coming soon',
        false,
      ),
      (
        'flutterwave',
        'Flutterwave',
        'Card, mobile money, international — coming soon',
        false,
      ),
      ('manual', 'Bank transfer', 'Show account details instead', true),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
        children: [
          const DetailHeader('Giving'),
          const SizedBox(height: 18),
          Text(
            '“Every man according as he purposeth in his heart, so let him give.”',
            style: WgnText.serif(15, color: c.txt2, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text(
            '2 CORINTHIANS 9:7',
            style: WgnText.mono(10.5, color: c.gold),
          ),
          const SizedBox(height: 24),
          Text(
            'PURPOSE',
            style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p
                  in giving?.purposes ?? ['Offering', 'Tithe', 'First Fruit'])
                PillChip(
                  label: p,
                  selected: purpose == p,
                  onTap: () => ref.read(_purposeProvider.notifier).state = p,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'AMOUNT',
            style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surf,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Text(
                  giving?.currency ?? '₦',
                  style: WgnText.ui(13, weight: FontWeight.w700, color: c.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        ref.read(_amountProvider.notifier).state = v,
                    style: WgnText.ui(
                      20,
                      weight: FontWeight.w700,
                      color: c.txt,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintText: '0.00',
                      hintStyle: WgnText.ui(
                        20,
                        weight: FontWeight.w700,
                        color: c.txt3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final preset in giving?.presets ?? [5000, 10000, 25000])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        final v = NumberFormat('#,###').format(preset);
                        _amountCtrl.text = v;
                        ref.read(_amountProvider.notifier).state = v;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.line2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${giving?.currency ?? '₦'}${NumberFormat('#,###').format(preset)}',
                          style: WgnText.ui(
                            11.5,
                            weight: FontWeight.w600,
                            color: c.txt2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'PAY WITH',
            style: WgnText.mono(10, color: c.txt3, letterSpacing: 1.6),
          ),
          for (final (key, name, note, enabled) in rails)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onTap: enabled
                    ? () => ref.read(_railProvider.notifier).state = key
                    : () => ref
                          .read(toastProvider.notifier)
                          .show('$name is coming in a later update'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: rail == key ? c.accentSoft : c.surf,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rail == key ? c.accent : c.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: WgnText.ui(
                                12.5,
                                weight: FontWeight.w700,
                                color: enabled ? c.txt : c.txt3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(note, style: WgnText.ui(10.5, color: c.txt3)),
                          ],
                        ),
                      ),
                      if (rail == key)
                        Icon(Icons.check_rounded, size: 16, color: c.gold),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          WgnButton(
            label: amount.trim().isEmpty
                ? 'Continue to payment'
                : 'Give ${giving?.currency ?? '₦'}$amount · $purpose',
            onTap: () {
              if (amount.trim().isEmpty) {
                ref.read(toastProvider.notifier).show('Enter an amount first');
                return;
              }
              showGivingDetailsSheet(context);
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Bank transfer and mobile details are also under\nMore → Giving details.',
              textAlign: TextAlign.center,
              style: WgnText.ui(10.5, color: c.txt3, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
