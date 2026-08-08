import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Rehnumai app theme — maps the Tailwind design tokens to Flutter's ThemeData.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceBright,
      textTheme: AppTextStyles.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineLgMobile.copyWith(
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.surfaceContainerHigh,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.labelCaps),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onSurface);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelCaps,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceBright,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Text styles matching the Tailwind fontSize tokens.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get headlineXl => GoogleFonts.manrope(
        fontSize: 40,
        height: 48 / 40,
        letterSpacing: -0.02 * 40,
        fontWeight: FontWeight.w800,
      );

  static TextStyle get headlineLg => GoogleFonts.manrope(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.manrope(
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get headlineMd => GoogleFonts.manrope(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLg => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMd => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySm => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get dataMono => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: 0.02 * 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelCaps => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        fontWeight: FontWeight.w700,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: headlineXl,
        displayMedium: headlineLg,
        displaySmall: headlineLgMobile,
        headlineLarge: headlineLg,
        headlineMedium: headlineMd,
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelSmall: labelCaps,
        labelMedium: dataMono,
      );
}

