import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Rehnumai app theme — maps the Tailwind design tokens to Flutter's ThemeData.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
        surface: AppColors.surfaceBright,
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
      cardColor: AppColors.surfaceContainerLowest,
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
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceBright,
        titleTextStyle: AppTextStyles.headlineMd.copyWith(color: AppColors.onSurface),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
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
        fillColor: AppColors.surfaceContainerLowest,
        labelStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        floatingLabelStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFF26D5B),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF871F15),
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFFE3C36D),
        onSecondary: Colors.black,
        secondaryContainer: Color(0xFF584400),
        onSecondaryContainer: Colors.white,
        tertiary: Color(0xFF84A98C),
        onTertiary: Colors.black,
        tertiaryContainer: Color(0xFF2C4E36),
        onTertiaryContainer: Colors.white,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Colors.white,
        surface: AppColors.darkSurfaceBright,
        onSurface: AppColors.darkInkText,
        onSurfaceVariant: AppColors.darkOnSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.darkOutlineVariant,
        inverseSurface: AppColors.surfaceBright,
        onInverseSurface: AppColors.onSurface,
        inversePrimary: AppColors.primary,
        surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
        surfaceContainerLow: AppColors.darkSurfaceContainerLow,
        surfaceContainer: AppColors.darkSurfaceContainerLow,
        surfaceContainerHigh: Color(0xFF382F28),
        surfaceContainerHighest: Color(0xFF42372F),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkSurfaceBright,
      cardColor: AppColors.darkSurfaceContainerLowest,
      textTheme: AppTextStyles.darkTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurfaceBright,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineLgMobile.copyWith(
          color: const Color(0xFFF26D5B),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFF26D5B)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceContainerLowest,
        indicatorColor: const Color(0xFF382F28),
        labelTextStyle: WidgetStateProperty.all(
          AppTextStyles.labelCaps.copyWith(color: AppColors.darkInkText),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF26D5B));
          }
          return const IconThemeData(color: AppColors.darkOnSurfaceVariant);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceContainerLowest,
        titleTextStyle: AppTextStyles.headlineMd.copyWith(color: AppColors.darkInkText),
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.darkInkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkOutlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF26D5B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.labelCaps,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceContainerLowest,
        labelStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.darkOnSurfaceVariant,
        ),
        floatingLabelStyle: AppTextStyles.bodySm.copyWith(
          color: const Color(0xFFF26D5B),
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF26D5B), width: 2),
        ),
        hintStyle: AppTextStyles.bodySm.copyWith(
          color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.7),
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
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.manrope(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.01 * 32,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.manrope(
        fontSize: 26,
        height: 32 / 26,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.manrope(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      );

  static TextStyle get dataMono => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        height: 18 / 14,
        letterSpacing: 0.02 * 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get labelCaps => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
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

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: headlineXl.copyWith(color: AppColors.darkInkText),
        displayMedium: headlineLg.copyWith(color: AppColors.darkInkText),
        displaySmall: headlineLgMobile.copyWith(color: AppColors.darkInkText),
        headlineLarge: headlineLg.copyWith(color: AppColors.darkInkText),
        headlineMedium: headlineMd.copyWith(color: AppColors.darkInkText),
        bodyLarge: bodyLg.copyWith(color: AppColors.darkInkText),
        bodyMedium: bodyMd.copyWith(color: AppColors.darkInkText),
        bodySmall: bodySm.copyWith(color: AppColors.darkOnSurfaceVariant),
        labelSmall: labelCaps.copyWith(color: AppColors.darkInkText),
        labelMedium: dataMono.copyWith(color: AppColors.darkInkText),
      );
}
