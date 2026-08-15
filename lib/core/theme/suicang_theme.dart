import 'package:flutter/material.dart';

class SuicangTheme {
  static const primary = Color(0xFF6C5CE7);
  static const background = Color(0xFFF5F6FB);
  static const ink = Color(0xFF171923);
  static const muted = Color(0xFF858A9B);
  static const line = Color(0xFFE9EAF1);
  static const soft = Color(0xFFEEEAFD);
  static const brandGradient = LinearGradient(colors: [Color(0xFF6554DF), Color(0xFFA98CFB)]);
  static const heroGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF252342), Color(0xFF4B4278), Color(0xFF9076CB)]);

  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: dark ? const Color(0xFF171820) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF111318) : background,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
