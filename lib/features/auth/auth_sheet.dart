import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/wgn_colors.dart';
import '../../core/theme/wgn_theme.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/wgn_widgets.dart';
import '../../data/repositories.dart';
import '../../data/supabase_client.dart';
import '../../data/user_state.dart';

/// Guest → account upgrade (links email onto the anonymous session so likes,
/// streaks and downloads carry over) or plain sign-in.
void showAuthSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AuthSheet(),
  );
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet();

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signIn = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _error = 'Enter an email and a password (6+ characters)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_signIn) {
        await supa.auth.signInWithPassword(email: email, password: password);
      } else {
        // Upgrade the anonymous session in place.
        await supa.auth.updateUser(UserAttributes(
          email: email,
          password: password,
          data: {'full_name': _name.text.trim()},
        ));
        final uid = supa.auth.currentUser?.id;
        if (uid != null && _name.text.trim().isNotEmpty) {
          await supa
              .from('profiles')
              .update({'full_name': _name.text.trim()}).eq('id', uid);
        }
      }
      ref.invalidate(profileProvider);
      await ref.read(userStateProvider.notifier).reload();
      if (mounted) {
        Navigator.of(context).pop();
        ref.read(toastProvider.notifier).show(_signIn
            ? 'Welcome back'
            : 'Account created — you’re all set');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong — try again');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
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
            Text(_signIn ? 'Sign in' : 'Create your account',
                style: WgnText.display(19, color: c.txt)),
            const SizedBox(height: 6),
            Text(
              _signIn
                  ? 'Pick up your streaks, saves and giving history.'
                  : 'Keeps your streak, saves and registrations across devices.',
              style: WgnText.ui(11.5, color: c.txt2, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (!_signIn) _field(_name, 'Full name'),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress),
            _field(_password, 'Password', obscure: true),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!,
                    style: WgnText.ui(11.5,
                        color: const Color(0xFFE0483B), height: 1.4)),
              ),
            WgnButton(
              label: _busy
                  ? 'One moment…'
                  : (_signIn ? 'Sign in' : 'Create account'),
              onTap: _busy ? null : _submit,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _oauthButton('Google',
                      () => ref.read(toastProvider.notifier).show(
                          'Google sign-in arrives with the hosted backend')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _oauthButton('Apple',
                      () => ref.read(toastProvider.notifier).show(
                          'Apple sign-in arrives with the hosted backend')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: () => setState(() {
                  _signIn = !_signIn;
                  _error = null;
                }),
                child: Text(
                  _signIn
                      ? 'New here? Create an account'
                      : 'Already have an account? Sign in',
                  style: WgnText.ui(11.5,
                      weight: FontWeight.w600, color: c.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
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
        obscureText: obscure,
        keyboardType: keyboard,
        autocorrect: false,
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

  Widget _oauthButton(String label, VoidCallback onTap) {
    final c = context.wgn;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: c.line2),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text('Continue with $label',
            style: WgnText.ui(11.5, weight: FontWeight.w600, color: c.txt2)),
      ),
    );
  }
}
