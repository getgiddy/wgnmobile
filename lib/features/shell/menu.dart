import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/toast.dart';
import '../../data/repositories.dart';
import '../../services/download_manager.dart';
import '../giving/giving_details_sheet.dart';

class WgnMenuItem {
  const WgnMenuItem({this.head, required this.label, this.hint = '', this.go});
  final String? head;
  final String label;
  final String hint;
  final void Function(BuildContext context)? go;
}

/// Menu backing the More screen, per the design.
List<WgnMenuItem> buildMenu(WidgetRef ref) {
  final journal = ref.watch(journalProvider).valueOrNull;
  final updates = ref.watch(updatesProvider).valueOrNull;
  final events = ref.watch(eventsProvider).valueOrNull;
  final dlCount = ref.watch(downloadsProvider).count;

  void toast(BuildContext context, String msg) =>
      ref.read(toastProvider.notifier).show(msg);

  return [
    WgnMenuItem(
      head: 'MEDIA',
      label: 'The Journal',
      hint: journal == null || journal.isEmpty
          ? ''
          : 'Issue ${journal.first.issueNo}',
      go: (c) => c.push('/journal'),
    ),
    WgnMenuItem(
      label: 'Updates',
      hint: updates == null || updates.isEmpty ? '' : '${updates.length} new',
      go: (c) => c.push('/updates'),
    ),
    WgnMenuItem(
      label: 'Offline library',
      hint: '$dlCount',
      go: (c) => c.push('/downloads'),
    ),
    WgnMenuItem(
      label: 'Broadcast platforms',
      go: (c) => c.go('/live'),
    ),
    WgnMenuItem(
      head: 'CONNECT',
      label: 'Prayer requests',
      go: (c) => c.push('/prayer'),
    ),
    WgnMenuItem(
      label: 'Testimonies',
      go: (c) => c.push('/testimonies'),
    ),
    WgnMenuItem(
      label: 'Events & registration',
      hint: events == null || events.isEmpty ? '' : '${events.length} open',
      go: (c) => c.push('/events'),
    ),
    WgnMenuItem(
      label: 'Serve on a team',
      go: (c) => toast(c, 'Volunteer form opens in browser'),
    ),
    WgnMenuItem(
      head: 'GIVE & ABOUT',
      label: 'Giving',
      go: (c) => c.push('/giving'),
    ),
    WgnMenuItem(
      label: 'Giving details',
      go: showGivingDetailsSheet,
    ),
    WgnMenuItem(
      label: 'About WordFeast',
      go: (c) => c.push('/about'),
    ),
  ];
}
