import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wgn_colors.dart';

/// Typography helpers matching the design: Sora for UI, Newsreader for
/// devotional/display text, Space Mono for eyebrow labels and stamps.
class WgnText {
  static TextStyle ui(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.sora(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// Newsreader. Body copy and pull quotes sit at w400; display headings
  /// (screen titles, devotional titles) at w500 — the design uses no others.
  static TextStyle serif(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    FontStyle? style,
    double? letterSpacing,
  }) =>
      GoogleFonts.newsreader(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontStyle: style,
        letterSpacing: letterSpacing,
      );

  /// Serif display heading — w500 with the design's -0.01em tracking.
  static TextStyle display(double size, {Color? color, double? height}) =>
      serif(
        size,
        weight: FontWeight.w500,
        color: color,
        height: height,
        letterSpacing: size * -0.01,
      );

  /// Space Mono ships a single upright weight, so `weight` is fixed at w400.
  static TextStyle mono(
    double size, {
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Gold eyebrow label, e.g. "CONTINUE LISTENING".
  static TextStyle eyebrow(WgnColors c, {double size = 10}) =>
      mono(size, color: c.gold, letterSpacing: size * 0.16);
}

ThemeData buildWgnTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? WgnColors.dark : WgnColors.light;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: brightness,
      surface: c.bg,
      primary: c.accent,
      onPrimary: c.onAccent,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: c.txt,
      displayColor: c.txt,
    ),
    dividerColor: c.line,
    extensions: [c],
  );
}
