import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// BurnIn Typography
/// - Display/Wordmark: Oswald (bold condensed caps — "BURNIN" style)
/// - Headlines: Oswald SemiBold
/// - Body / Labels: Inter
class AppTextStyles {
  AppTextStyles._();

  // ─── Wordmark / Display ────────────────────────────────────────────────
  static TextStyle get wordmark => GoogleFonts.oswald(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.maroon,
      );

  static TextStyle get wordmarkLight => GoogleFonts.oswald(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppColors.textPrimaryDark,
      );

  static TextStyle get tagline => GoogleFonts.oswald(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 6,
        color: AppColors.amber,
      );

  // ─── Headlines ─────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.oswald(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.oswald(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  // ─── Body ──────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  // ─── Labels / Buttons ──────────────────────────────────────────────────
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // ─── Price ─────────────────────────────────────────────────────────────
  static TextStyle get price => GoogleFonts.oswald(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.amber,
      );

  static TextStyle get priceTotal => GoogleFonts.oswald(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.amber,
        letterSpacing: 0.5,
      );

  // ─── Category pill ─────────────────────────────────────────────────────
  static TextStyle get pill => GoogleFonts.oswald(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      );
}
