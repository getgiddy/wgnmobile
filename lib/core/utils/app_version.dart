import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version stamp shown in More and About, e.g. `WGN MOBILE · 1.0.0 (1)`.
///
/// Read from the bundle rather than hardcoded so it cannot drift from
/// pubspec.yaml — a stale string here is wrong metadata shown to users.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'WGN MOBILE · ${info.version} (${info.buildNumber})';
});
