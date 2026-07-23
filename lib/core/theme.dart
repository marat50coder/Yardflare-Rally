import 'package:flutter/material.dart';

/// Shared colours and text styles for the cartoon night-farm look.
class AppColors {
  AppColors._();

  static const nightTop = Color(0xFF1B2A4A);
  static const nightBottom = Color(0xFF243B2E);
  static const panel = Color(0xFF2C3E50);
  static const panelLight = Color(0xFF3A5068);
  static const accent = Color(0xFFFFC64B); // warm lantern glow
  static const accentDark = Color(0xFFE8A020);
  static const danger = Color(0xFFE74C3C);
  static const safe = Color(0xFF8BC34A);
  static const coin = Color(0xFFFFD24B);
  static const textLight = Color(0xFFFDF6E3);
  static const textDim = Color(0xFFB9C4CE);

  // Themed menu-action colours so each destination has its own identity
  // instead of a row of identical grey panels.
  static const play = Color(0xFF5FC64B); // fresh green
  static const endless = Color(0xFF7A6CF0); // twilight violet
  static const upgrades = Color(0xFF33A7C2); // teal
  static const skins = Color(0xFFE85C9C); // pink
  static const tasks = Color(0xFFF08C3A); // ember orange
  static const help = Color(0xFF56C7E0); // info cyan
}

class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(surface: AppColors.panel),
      scaffoldBackgroundColor: AppColors.nightBottom,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textLight,
        displayColor: AppColors.textLight,
      ),
    );
  }

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.nightTop, AppColors.nightBottom],
  );
}
