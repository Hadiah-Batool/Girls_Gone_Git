import 'package:flutter/material.dart';

/// All color tokens from the Rehnumai design system.
/// Values match the Tailwind config in the HTML prototypes exactly.
class AppColors {
  AppColors._();

  // ── Surface & Background ─────────────────────────────────────────────────
  static const Color surfaceBright = Color(0xFFFFF8EF);
  static const Color surface = Color(0xFFFFF8EF);
  static const Color background = Color(0xFFFFF8EF);
  static const Color sandBg = Color(0xFFF2E8CF);
  static const Color surfaceDim = Color(0xFFE3D9C1);
  static const Color surfaceVariant = Color(0xFFECE2C9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFDF3DA);
  static const Color surfaceContainer = Color(0xFFF7EDD4);
  static const Color surfaceContainerHigh = Color(0xFFF1E8CF);
  static const Color surfaceContainerHighest = Color(0xFFECE2C9);
  static const Color inverseSurface = Color(0xFF35301F);
  static const Color inverseOnSurface = Color(0xFFFAF0D7);

  // ── On-Surface ────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF201B0C);
  static const Color onSurfaceVariant = Color(0xFF58413E);
  static const Color onBackground = Color(0xFF201B0C);
  static const Color inkText = Color(0xFF2D2D2D);

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFA8372A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF26D5B);
  static const Color onPrimaryContainer = Color(0xFF650302);
  static const Color primaryFixed = Color(0xFFFFDAD5);
  static const Color primaryFixedDim = Color(0xFFFFB4A8);
  static const Color onPrimaryFixed = Color(0xFF410000);
  static const Color onPrimaryFixedVariant = Color(0xFF871F15);
  static const Color inversePrimary = Color(0xFFFFB4A8);
  static const Color surfaceTint = Color(0xFFA8372A);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF735B0D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFEDC83);
  static const Color onSecondaryContainer = Color(0xFF786012);
  static const Color secondaryFixed = Color(0xFFFFE08E);
  static const Color secondaryFixedDim = Color(0xFFE3C36D);
  static const Color onSecondaryFixed = Color(0xFF241A00);
  static const Color onSecondaryFixedVariant = Color(0xFF584400);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF43664D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF7A9F82);
  static const Color onTertiaryContainer = Color(0xFF133520);
  static const Color tertiaryFixed = Color(0xFFC5ECCC);
  static const Color tertiaryFixedDim = Color(0xFFAAD0B1);
  static const Color onTertiaryFixed = Color(0xFF00210E);
  static const Color onTertiaryFixedVariant = Color(0xFF2C4E36);
  static const Color terracottaDark = Color(0xFFBC6C4D);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8B716D);
  static const Color outlineVariant = Color(0xFFDFBFBB);

  // ── Risk Levels ───────────────────────────────────────────────────────────
  static const Color riskHigh = Color(0xFFF26D5B);
  static const Color riskMedium = Color(0xFFF4D37B);
  static const Color riskStable = Color(0xFF84A98C);
}
