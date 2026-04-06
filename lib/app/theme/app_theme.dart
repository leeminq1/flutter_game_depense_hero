import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors ──
  static const Color ink = Color(0xFFF0F4F8);
  static const Color inkMuted = Color(0xFFA1AFBF);
  static const Color line = Color(0xFF334E68);
  
  static const Color panel = Color(0xFF102A43);
  static const Color steel = Color(0xFF486581);
  static const Color ember = Color(0xFFEF4E4E);
  static const Color moss = Color(0xFF38D39F);
  static const Color glowBox = Color(0xFF243B53);

  // ── Layout ──
  static const double cardRadius = 24.0;
  static const double panelPadding = 16.0;

  // ── Gradients ──
  static const BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF102A43),
        Color(0xFF071B2F),
      ],
    ),
  );

  static const BoxDecoration cardDecoration = BoxDecoration(
    color: panel,
    borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
  );

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF071B2F),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: ink,
          fontFamily: 'Inter',
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: inkMuted,
        ),
      ),
    );
  }
}
