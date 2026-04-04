import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData data() {
    const parchment = Color(0xFFF0E1C2);
    const bark = Color(0xFF3A2A1D);
    const moss = Color(0xFF5B7A45);
    const ember = Color(0xFFBF6B3D);
    const dusk = Color(0xFF17212B);

    final scheme = ColorScheme.fromSeed(
      seedColor: moss,
      brightness: Brightness.dark,
    ).copyWith(
      primary: moss,
      secondary: ember,
      surface: dusk,
      onSurface: parchment,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: dusk,
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: parchment,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: parchment,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: parchment,
        ),
      ),
      cardTheme: const CardThemeData(
        color: bark,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ember,
        thumbColor: parchment,
        inactiveTrackColor: bark.withValues(alpha: 0.8),
      ),
    );
  }
}
