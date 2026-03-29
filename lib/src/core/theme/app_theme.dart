import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFFF08FA6);
  static const background = Color(0xFFFFF8F4);
  static const card = Colors.white;
  static const peach = Color(0xFFFFD9C7);
  static const lavender = Color(0xFFE7D9FF);
  static const mint = Color(0xFFDDF4E7);
  static const ink = Color(0xFF2C2A3A);

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: ink,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: ink.withValues(alpha: 0.78),
          height: 1.35,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
