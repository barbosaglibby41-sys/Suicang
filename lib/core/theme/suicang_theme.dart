import 'package:flutter/material.dart';

class SuicangTheme {
  static const primary = Color(0xFF6956E8);
  static const background = Color(0xFFF8F8FC);
  static const ink = Color(0xFF17171C);
  static const muted = Color(0xFF777681);
  static const line = Color(0xFFE7E6ED);
  static const soft = Color(0xFFEEEBFF);
  static const brandGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5142D7), Color(0xFF9B82FF)]);
  static const heroGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF16151D), Color(0xFF2C2943), Color(0xFF5C4A8B)]);

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
      scaffoldBackgroundColor: dark ? const Color(0xFF050506) : background,
      fontFamily: 'SF Pro Display',
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
