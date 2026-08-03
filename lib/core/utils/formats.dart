import 'package:intl/intl.dart';

/// "58:02" or "1:52:04" from seconds.
String formatDuration(int secs) {
  final h = secs ~/ 3600, m = (secs % 3600) ~/ 60, s = secs % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// "58 min" or "1h 52m" from seconds.
String formatMins(int secs) {
  final h = secs ~/ 3600, m = ((secs % 3600) / 60).round();
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '$m min';
}

/// "82 MB" from bytes.
String formatSize(int? bytes) =>
    bytes == null ? '—' : '${(bytes / (1024 * 1024)).round()} MB';

/// "21 Jul, 2026"
String formatDate(DateTime d) => DateFormat('d MMM, yyyy').format(d);

/// "WED 24 JUL"
String formatDayStamp(DateTime d) =>
    DateFormat('EEE d MMM').format(d).toUpperCase();

/// "SUN 27 JUL · 9:00 AM"
String formatEventStamp(DateTime d) =>
    '${DateFormat('EEE d MMM').format(d).toUpperCase()} · ${DateFormat('h:mm a').format(d)}';

/// "9:00 AM · Main Auditorium"
String formatEventWhen(DateTime d, String where) =>
    '${DateFormat('h:mm a').format(d)} · $where';
