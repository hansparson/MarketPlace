import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Primary Palette ===
  static const Color midnightNavy = Color(0xFF0A1128);
  static const Color sovereignGold = Color(0xFFD4AF37);
  static const Color sovereignGoldDim = Color(0xFFAF8D11);

  // === Surface Layers (tonal layering for depth) ===
  static const Color surface = Color(0xFF121414);
  static const Color surfaceDim = Color(0xFF121414);
  static const Color surfaceContainerLowest = Color(0xFF0C0F0F);
  static const Color surfaceContainerLow = Color(0xFF1A1C1C);
  static const Color surfaceContainer = Color(0xFF1E2020);
  static const Color surfaceContainerHigh = Color(0xFF282A2B);
  static const Color surfaceContainerHighest = Color(0xFF333535);
  static const Color surfaceBright = Color(0xFF37393A);

  // === Text & Icon Colors ===
  static const Color onSurface = Color(0xFFE2E2E2);
  static const Color onSurfaceVariant = Color(0xFFC6C6CE);
  static const Color outline = Color(0xFF909098);
  static const Color outlineVariant = Color(0xFF46464D);

  // === Primary & Secondary ===
  static const Color primary = Color(0xFFBFC5E4);
  static const Color primaryContainer = Color(0xFF0A1128);
  static const Color onPrimary = Color(0xFF292F48);
  static const Color secondary = Color(0xFFE9C349);
  static const Color onSecondary = Color(0xFF3C2F00);
  static const Color secondaryContainer = Color(0xFFAF8D11);

  // === Semantic States ===
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFE9A849);

  // === Gold Gradient ===
  static const Gradient sovereignGoldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF5D170), Color(0xFFD4AF37)],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient navyDeepGradient = LinearGradient(
    colors: [Color(0xFF0A1128), Color(0xFF121C3B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === Glass Effect ===
  static Color get glassNavy => midnightNavy.withOpacity(0.7);
  static Color get glassSurface => surfaceContainerLow.withOpacity(0.6);
  static Color get goldBorder => sovereignGold.withOpacity(0.3);
  static Color get goldGlow => sovereignGold.withOpacity(0.12);
}
