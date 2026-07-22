import 'package:flutter/material.dart';

/// BurnIn Brand Colors
/// Palette: Deep Maroon + Orange/Amber Flame Gradient
class AppColors {
  AppColors._();

  // ── Primary palette ─────────────────────────────────────────────────────────
  static const Color maroon = Color(0xFF8B0000);
  static const Color maroonLight = Color(0xFFB71C1C);
  static const Color maroonDark = Color(0xFF5C0000);

  // ── Flame / accent ──────────────────────────────────────────────────────────
  static const Color amber = Color(0xFFFF8C00);
  static const Color amberLight = Color(0xFFFFB300);
  static const Color orange = Color(0xFFFF6200);

  // Gradient stops (flame: maroon → amber)
  static const LinearGradient flameGradient = LinearGradient(
    colors: [maroon, orange, amber],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // Horizontal variant (for buttons)
  static const LinearGradient flameGradientHorizontal = LinearGradient(
    colors: [maroon, maroonLight, orange],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF252525);
  static const Color dividerDark = Color(0xFF2E2E2E);

  static const Color scaffoldLight = Color(0xFFF5F0F0); // warm off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFEEEE); // very light maroon tint

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color vegGreen = Color(0xFF4CAF50);
  static const Color nonVegRed = Color(0xFFD32F2F);
  static const Color cashTag = Color(0xFF388E3C);
  static const Color upiTag = Color(0xFF1976D2);
  static const Color errorRed = Color(0xFFCF6679);
  static const Color successGreen = Color(0xFF81C784);

  // ── Overlay ──────────────────────────────────────────────────────────────
  static const Color flameGlow = Color(0x40FF8C00); // amber at 25% opacity
  static const Color maroonGlow = Color(0x308B0000); // maroon at 19% opacity
}
