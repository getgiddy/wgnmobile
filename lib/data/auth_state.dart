import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// The signed-in user, kept in step with gotrue instead of sampled during
/// build.
///
/// Reading `supa.auth.currentUser` inline inside a `build` looks equivalent
/// but is not: nothing subscribes, so the widget keeps whatever it saw until
/// something unrelated happens to rebuild it. Sign-out, session restore, a
/// token refresh and an email upgrade all changed the user without the profile
/// screen ever hearing about it.
///
/// Seeded synchronously from the current session so there is no frame where a
/// signed-in user is rendered as a guest.
class AuthUserNotifier extends Notifier<User?> {
  @override
  User? build() {
    final sub = supa.auth.onAuthStateChange.listen(
      (data) => state = data.session?.user,
      onError: (Object _) => state = supa.auth.currentUser,
    );
    ref.onDispose(sub.cancel);
    return supa.auth.currentUser;
  }
}

final authUserProvider =
    NotifierProvider<AuthUserNotifier, User?>(AuthUserNotifier.new);

/// The address this account is reachable at, including one that has been
/// entered but not confirmed yet.
///
/// When confirmations are required, upgrading a guest with `updateUser` does
/// **not** populate `email`. gotrue parks the address in `new_email` and only
/// promotes it once the link is clicked — verified against gotrue 2.193 with
/// `mailer_autoconfirm: false`. Anything user-facing has to look at both, or a
/// member who just signed up appears to have no email at all.
String? accountEmail(User? user) {
  if (user == null) return null;
  final confirmed = user.email ?? '';
  if (confirmed.isNotEmpty) return confirmed;
  final pending = user.newEmail ?? '';
  return pending.isEmpty ? null : pending;
}

/// Whether this session is a guest — someone with no way back into the account
/// on another device.
///
/// `isAnonymous` on its own is not that test, and neither is `email`. On the
/// guest-upgrade path gotrue leaves `is_anonymous` true *and* `email` empty
/// until the confirmation link is clicked, so both of the obvious checks say
/// "guest" about someone who has just set an email and a password. They would
/// be shown "Browsing as a guest", a "Create account" button and no way to
/// sign out — while signed in.
///
/// So: anyone who has given us an address, confirmed or not, or linked a
/// Google or Apple identity, has an account.
final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return true;
  if (!user.isAnonymous) return false;
  if (accountEmail(user) != null) return false;
  return (user.identities ?? const []).isEmpty;
});

/// Set between an email sign-up and the click on the confirmation link. The
/// account works on this device, but the address is unverified — and on the
/// guest-upgrade path it is not yet usable to sign in anywhere else — so the
/// profile screen says so rather than implying everything is settled.
final awaitingEmailConfirmationProvider = Provider<bool>((ref) {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  // A pending address is unconfirmed by definition.
  if ((user.newEmail ?? '').isNotEmpty) return true;
  return (user.email ?? '').isNotEmpty && user.emailConfirmedAt == null;
});
