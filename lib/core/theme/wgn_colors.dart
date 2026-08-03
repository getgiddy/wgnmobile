import 'package:flutter/material.dart';

/// Design tokens from the WGN App design spec (dark + light).
@immutable
class WgnColors extends ThemeExtension<WgnColors> {
  const WgnColors({
    required this.bg,
    required this.surf,
    required this.surf2,
    required this.nav,
    required this.plum,
    required this.line,
    required this.line2,
    required this.txt,
    required this.txt2,
    required this.txt3,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.gold,
    required this.gold2,
    required this.ph1,
    required this.ph2,
    required this.scrim,
  });

  final Color bg;
  final Color surf;
  final Color surf2;
  final Color nav;
  final Color plum;
  final Color line;
  final Color line2;
  final Color txt;
  final Color txt2;
  final Color txt3;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color gold;
  final Color gold2;
  final Color ph1;
  final Color ph2;
  final Color scrim;

  static const dark = WgnColors(
    bg: Color(0xFF17101F),
    surf: Color(0xFF211729),
    surf2: Color(0xFF2B2033),
    nav: Color(0xFF1C1425),
    plum: Color(0xFF2E1240),
    line: Color(0x17F5F1F7),
    line2: Color(0x29F5F1F7),
    txt: Color(0xFFF5F1F7),
    txt2: Color(0x8CF5F1F7),
    txt3: Color(0x6BF5F1F7),
    accent: Color(0xFFD4AF54),
    onAccent: Color(0xFF17101F),
    accentSoft: Color(0x1FD4AF54),
    gold: Color(0xFFD4AF54),
    gold2: Color(0xFFE8CE8A),
    ph1: Color(0xFF3B1A4E),
    ph2: Color(0xFF31173F),
    scrim: Color(0xB80A060E),
  );

  static const light = WgnColors(
    bg: Color(0xFFFBF8F3),
    surf: Color(0xFFFFFFFF),
    surf2: Color(0xFFF1EBE1),
    nav: Color(0xFFFFFFFF),
    plum: Color(0xFF4A2060),
    line: Color(0x1A1E1425),
    line2: Color(0x291E1425),
    txt: Color(0xFF1E1425),
    txt2: Color(0x991E1425),
    txt3: Color(0x731E1425),
    accent: Color(0xFF4A2060),
    onAccent: Color(0xFFFFF9EA),
    accentSoft: Color(0x124A2060),
    gold: Color(0xFF8A6A12),
    gold2: Color(0xFF6E5310),
    ph1: Color(0xFFE4DCD0),
    ph2: Color(0xFFD9CFC0),
    scrim: Color(0x801E1425),
  );

  @override
  WgnColors copyWith({
    Color? bg,
    Color? surf,
    Color? surf2,
    Color? nav,
    Color? plum,
    Color? line,
    Color? line2,
    Color? txt,
    Color? txt2,
    Color? txt3,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? gold,
    Color? gold2,
    Color? ph1,
    Color? ph2,
    Color? scrim,
  }) {
    return WgnColors(
      bg: bg ?? this.bg,
      surf: surf ?? this.surf,
      surf2: surf2 ?? this.surf2,
      nav: nav ?? this.nav,
      plum: plum ?? this.plum,
      line: line ?? this.line,
      line2: line2 ?? this.line2,
      txt: txt ?? this.txt,
      txt2: txt2 ?? this.txt2,
      txt3: txt3 ?? this.txt3,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      gold: gold ?? this.gold,
      gold2: gold2 ?? this.gold2,
      ph1: ph1 ?? this.ph1,
      ph2: ph2 ?? this.ph2,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  WgnColors lerp(ThemeExtension<WgnColors>? other, double t) {
    if (other is! WgnColors) return this;
    return WgnColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surf: Color.lerp(surf, other.surf, t)!,
      surf2: Color.lerp(surf2, other.surf2, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
      line: Color.lerp(line, other.line, t)!,
      line2: Color.lerp(line2, other.line2, t)!,
      txt: Color.lerp(txt, other.txt, t)!,
      txt2: Color.lerp(txt2, other.txt2, t)!,
      txt3: Color.lerp(txt3, other.txt3, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      gold2: Color.lerp(gold2, other.gold2, t)!,
      ph1: Color.lerp(ph1, other.ph1, t)!,
      ph2: Color.lerp(ph2, other.ph2, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension WgnColorsX on BuildContext {
  WgnColors get wgn => Theme.of(this).extension<WgnColors>()!;
}
