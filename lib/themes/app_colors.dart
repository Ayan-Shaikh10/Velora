import 'package:flutter/material.dart';

/// Shared visual palette for the app. Prefer ColorScheme values in widgets;
/// use these constants for brand and semantic accents.
class AppColors {
  AppColors._();

  // Brand: calm indigo for primary actions, teal for progress/successful work.
  static const Color primary = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF0F766E);
  static const Color secondaryLight = Color(0xFF2DD4BF);

  // Light surfaces.
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF2FF);
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF172033);
  static const Color textLight = Color(0xFF64748B);

  // Dark surfaces.
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF131E2E);
  static const Color darkSurfaceVariant = Color(0xFF202D40);
  static const Color darkInputFill = Color(0xFF182538);
  static const Color darkBorder = Color(0xFF2B3A50);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFB5C1D2);

  // Semantic colors.
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFB91C1C);
  static const Color info = Color(0xFF2563EB);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
