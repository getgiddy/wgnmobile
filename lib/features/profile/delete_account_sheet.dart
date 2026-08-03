import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../../data/user_state.dart';

/// Account deletion, required by App Store guideline 5.1.1(v) and the
/// equivalent Play policy. Calls the `delete_account` RPC (migration 0002),
/// then drops the caller back into a fresh guest session.
void showDeleteAccountSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DeleteAccountSheet(),
  );
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  bool _busy = false;

  Future<void> _delete() async {
    setState(() => _busy = true);
    final messenger = ref.read(toastProvider.notifier);
    try {
      await supa.rpc<void>('delete_account');
      // The auth row is gone, so the current JWT no longer resolves. Clear it
      // and start a fresh guest session so the app has somewhere to land.
      await supa.auth.signOut();
      try {
        await supa.auth.signInAnonymously();
      } on AuthException catch (_) {}
      ref.invalidate(profileProvider);
      await ref.read(userStateProvider.notifier).reload();
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.show('Account deleted');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.show('Could not delete the account — try again');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    const danger = Color(0xFFE0483B);
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: c.nav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border.all(color: c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delete your account?', style: WgnText.display(19, color: c.txt)),
          const SizedBox(height: 6),
          Text(
            'This cannot be undone. We permanently delete your profile, saved '
            'devotionals, liked sermons, reading streak, event registrations, '
            'prayer requests and any testimonies you shared — including ones '
            'already published.',
            style: WgnText.ui(11.5, color: c.txt2, height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Sermons you downloaded stay on this phone until you remove them '
            'from Offline.',
            style: WgnText.ui(11.5, color: c.txt3, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _busy ? null : _delete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _busy ? c.surf2 : danger,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                _busy ? 'Deleting…' : 'Delete my account',
                style: WgnText.ui(
                  13.5,
                  weight: FontWeight.w700,
                  color: _busy ? c.txt3 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _busy ? null : () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'Keep my account',
                style: WgnText.ui(
                  13,
                  weight: FontWeight.w600,
                  color: c.txt2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
