import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locally persisted preferences: theme + wifi-only downloads.
class Prefs {
  const Prefs({this.themeMode = ThemeMode.dark, this.wifiOnly = true});

  final ThemeMode themeMode;
  final bool wifiOnly;

  Prefs copyWith({ThemeMode? themeMode, bool? wifiOnly}) => Prefs(
        themeMode: themeMode ?? this.themeMode,
        wifiOnly: wifiOnly ?? this.wifiOnly,
      );
}

class PrefsNotifier extends Notifier<Prefs> {
  static late SharedPreferences _sp;

  /// Called once from main() before runApp.
  static Future<void> init() async {
    _sp = await SharedPreferences.getInstance();
  }

  // Dev aid: `--dart-define=FORCE_THEME=light` for theme screenshots.
  static const _forceTheme = String.fromEnvironment('FORCE_THEME');

  @override
  Prefs build() => Prefs(
        themeMode: _forceTheme == 'light'
            ? ThemeMode.light
            : _sp.getString('theme') == 'light'
                ? ThemeMode.light
                : ThemeMode.dark,
        wifiOnly: _sp.getBool('wifiOnly') ?? true,
      );

  void toggleTheme() {
    final next =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(themeMode: next);
    _sp.setString('theme', next == ThemeMode.light ? 'light' : 'dark');
  }

  void toggleWifiOnly() {
    state = state.copyWith(wifiOnly: !state.wifiOnly);
    _sp.setBool('wifiOnly', state.wifiOnly);
  }
}

final prefsProvider = NotifierProvider<PrefsNotifier, Prefs>(PrefsNotifier.new);
