import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/auth_state.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';

/// Edit the details the member actually owns: their name and home branch.
///
/// Email is deliberately read-only here. Changing it is an auth operation, not
/// a profile one — gotrue mails both the old and new address (`config.toml`
/// sets `double_confirm_changes`) and the account is in a half-changed state
/// until both are clicked. That belongs in its own flow, not behind a field
/// that looks like the two next to it.
void showEditProfileSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _branch;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    _name = TextEditingController(text: profile?.fullName ?? '');
    _branch = TextEditingController(text: profile?.branch ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(authUserProvider)?.id;
    if (uid == null) {
      setState(() => _error = 'You’re not signed in');
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final branch = _branch.text.trim();
    try {
      await supa.from('profiles').update({
        'full_name': name,
        // Empty clears the row rather than storing '', so `?? 'Not set'` in the
        // profile screen keeps working.
        'branch': branch.isEmpty ? null : branch,
      }).eq('id', uid);
      ref.invalidate(profileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ref.read(toastProvider.notifier).show('Details saved');
    } catch (e) {
      debugPrint('profile update failed: $e');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not save — try again';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final Profile? profile = ref.watch(profileProvider).valueOrNull;
    final email =
        profile?.email ?? accountEmail(ref.watch(authUserProvider)) ?? '';

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: c.nav,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: c.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal details', style: WgnText.display(19, color: c.txt)),
            const SizedBox(height: 6),
            Text(
              'This is the name the welcome desk sees when they scan your code.',
              style: WgnText.ui(11.5, color: c.txt2, height: 1.5),
            ),
            const SizedBox(height: 18),
            _field(_name, 'Full name', capitalise: true),
            _field(_branch, 'Home branch'),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Signed in as $email',
                style: WgnText.ui(11, color: c.txt3, height: 1.5),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style: WgnText.ui(11.5,
                        color: const Color(0xFFE0483B), height: 1.4)),
              ),
            WgnButton(
              label: _busy ? 'Saving…' : 'Save',
              onTap: _busy ? null : _save,
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _busy ? null : () => Navigator.of(context).pop(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Cancel',
                    style: WgnText.ui(11.5,
                        weight: FontWeight.w600, color: c.txt2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool capitalise = false}) {
    final c = context.wgn;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.line),
      ),
      child: TextField(
        controller: ctrl,
        autocorrect: false,
        textCapitalization:
            capitalise ? TextCapitalization.words : TextCapitalization.none,
        style: WgnText.ui(13, color: c.txt),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          hintText: hint,
          hintStyle: WgnText.ui(13, color: c.txt3),
        ),
      ),
    );
  }
}
