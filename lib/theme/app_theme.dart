import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kAccentDefault = Color(0xFFFF7A00);
const kAccentOptions = [
  Color(0xFFFF7A00), Color(0xFFFF0033), Color(0xFF2E7DFF), Color(0xFF16A34A),
];

@immutable
class TubeboxColors extends ThemeExtension<TubeboxColors> {
  final Color bg, bg2, surface, surface2, text, text2, muted, faint, border, border2, error, accent;
  const TubeboxColors({
    required this.bg, required this.bg2, required this.surface, required this.surface2,
    required this.text, required this.text2, required this.muted, required this.faint,
    required this.border, required this.border2, required this.error, required this.accent,
  });

  static const light = TubeboxColors(
    bg: Color(0xFFFAFAFA), bg2: Color(0xFFF4F4F4), surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F7F7), text: Color(0xFF0A0A0A), text2: Color(0xFF404040),
    muted: Color(0xFF737373), faint: Color(0xFFA3A3A3), border: Color(0xFFEAEAEA),
    border2: Color(0xFFD4D4D4), error: Color(0xFFE04444), accent: kAccentDefault,
  );
  static const dark = TubeboxColors(
    bg: Color(0xFF0A0A0A), bg2: Color(0xFF0F0F0F), surface: Color(0xFF141414),
    surface2: Color(0xFF1A1A1A), text: Color(0xFFFAFAFA), text2: Color(0xFFD4D4D4),
    muted: Color(0xFF8A8A8A), faint: Color(0xFF5C5C5C), border: Color(0xFF1F1F1F),
    border2: Color(0xFF2A2A2A), error: Color(0xFFE04444), accent: kAccentDefault,
  );

  TubeboxColors withAccent(Color a) => TubeboxColors(
    bg: bg, bg2: bg2, surface: surface, surface2: surface2, text: text, text2: text2,
    muted: muted, faint: faint, border: border, border2: border2, error: error, accent: a,
  );

  @override
  TubeboxColors copyWith() => this;
  @override
  TubeboxColors lerp(ThemeExtension<TubeboxColors>? other, double t) =>
      other is TubeboxColors ? other : this;
}

class AppTheme {
  static ThemeData _build(TubeboxColors c, Brightness b) {
    final base = b == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.accent, brightness: b, primary: c.accent, surface: c.surface,
      ),
      textTheme: GoogleFonts.geistTextTheme(base.textTheme)
          .apply(bodyColor: c.text, displayColor: c.text),
      extensions: [c],
    );
  }

  static ThemeData light(Color accent) =>
      _build(TubeboxColors.light.withAccent(accent), Brightness.light);
  static ThemeData dark(Color accent) =>
      _build(TubeboxColors.dark.withAccent(accent), Brightness.dark);
}

extension TubeboxColorsX on BuildContext {
  TubeboxColors get c => Theme.of(this).extension<TubeboxColors>()!;
  TextStyle get mono => GoogleFonts.geistMono();
}
