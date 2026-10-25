import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central Material 3 theme. Shared components should use Theme.of(context)
/// so surfaces, text, borders, and controls stay consistent in light/dark mode.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final text = isDark ? AppColors.darkText : AppColors.textDark;
    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textLight;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final secondary = isDark ? AppColors.secondaryLight : AppColors.secondary;
    final inputFill = isDark ? AppColors.darkInputFill : AppColors.inputFill;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
      error: AppColors.error,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: isDark ? AppColors.black : Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: secondaryText,
      outline: secondaryText.withValues(alpha: 0.65),
      outlineVariant: border,
      error: isDark ? const Color(0xFFF87171) : AppColors.error,
    );

    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: text, displayColor: text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: baseTextTheme.copyWith(
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border.withValues(alpha: 0.8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: border.withValues(alpha: 0.8)),
        ),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: secondaryText,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF263449) : const Color(0xFF172033),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.35),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(color: secondaryText.withValues(alpha: 0.8)),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: isDark ? 0.22 : 0.11),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return baseTextTheme.labelSmall?.copyWith(
            color: selected ? primary : secondaryText,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? primary : secondaryText,
        )),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.12),
        circularTrackColor: primary.withValues(alpha: 0.12),
        refreshBackgroundColor: surface,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: secondaryText.withValues(alpha: 0.65), width: 1.4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inputFill,
        selectedColor: primary.withValues(alpha: 0.12),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        labelStyle: baseTextTheme.labelMedium?.copyWith(color: text),
        secondaryLabelStyle: baseTextTheme.labelMedium?.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    );
  }
}
