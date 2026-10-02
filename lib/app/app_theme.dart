import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material 3 theme configuration for ED-Operador using the Kigo brand colors.
///
/// The light theme uses the Kigo orange (`0xFFFF6900`) as primary, a warm
/// background, and the full input decoration spec from the Kigo design system.
/// The dark theme derives from the same seed for consistency.
class AppTheme {
  const AppTheme._();

  /// The Kigo brand seed color from which color schemes are derived.
  static const Color seedColor = AppColors.kigo500;

  /// The Material 3 light theme (Kigo brand).
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      primary: AppColors.kigo500,
      error: AppColors.red500,
      surface: AppColors.white,
    ).copyWith(
      primary: AppColors.kigo500,
      onPrimary: AppColors.white,
    );

    final baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppColors.neutral900,
          displayColor: AppColors.neutral900,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: AppColors.kigo500,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: baseTextTheme,
      splashColor: AppColors.splash,
      highlightColor: AppColors.highlight,
      focusColor: AppColors.splash,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.kigo500,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppSizes.ctaHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kigo500,
          minimumSize: const Size.fromHeight(AppSizes.ctaHeight),
          side: const BorderSide(color: AppColors.kigo500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme,
    );
  }

  /// The Material 3 dark theme derived from the Kigo seed.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: AppColors.kigo500,
      error: AppColors.red500,
    ).copyWith(
      primary: AppColors.kigo500,
      onPrimary: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: AppColors.kigo500,
      splashColor: AppColors.splash,
      highlightColor: AppColors.highlight,
      focusColor: AppColors.splash,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.kigo500,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(AppSizes.ctaHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kigo500,
          minimumSize: const Size.fromHeight(AppSizes.ctaHeight),
          side: const BorderSide(color: AppColors.kigo500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
    );
  }

  /// Input decoration theme matching the Kigo design system.
  static const InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    isDense: true,
    fillColor: AppColors.umbral100,
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    hintStyle: TextStyle(
      color: AppColors.slate400,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    helperStyle: TextStyle(
      color: AppColors.slate500,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    errorStyle: TextStyle(
      color: AppColors.red500,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      borderSide: BorderSide(color: AppColors.umbral200, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      borderSide: BorderSide(color: AppColors.kigo500, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      borderSide: BorderSide(color: AppColors.red500, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      borderSide: BorderSide(color: AppColors.red500, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      borderSide: BorderSide(color: AppColors.umbral200, width: 1.5),
    ),
  );
}
