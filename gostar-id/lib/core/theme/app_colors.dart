import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF001E40);
  static const Color primaryContainer = Color(0xFF003366);
  static const Color onPrimaryContainer = Color(0xFF799DD6);
  static const Color secondary = Color(0xFF006A6A);
  static const Color secondaryContainer = Color(0xFF90EFEF);
  static const Color onSecondaryContainer = Color(0xFF006E6E);
  static const Color secondaryFixed = Color(0xFF93F2F2);
  static const Color secondaryFixedDim = Color(0xFF76D6D5);
  static const Color tertiary = Color(0xFF705D00);
  static const Color tertiaryContainer = Color(0xFFC9A900);
  static const Color onTertiaryContainer = Color(0xFF4C3E00);
  static const Color tertiaryFixed = Color(0xFFFFE16D);

  // Surface & Neutral Colors
  static const Color background = Color(0xFFF8FAFB);
  static const Color surface = Color(0xFFF8FAFB);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF43474F);
  static const Color surfaceVariant = Color(0xFFE1E3E4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F5);
  static const Color surfaceContainer = Color(0xFFECEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE6E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFEFF1F2);
  static const Color primaryFixedDim = Color(0xFFA7C8FF);
  static const Color onPrimaryFixedVariant = Color(0xFF1F477B);
  
  // Outline & Borders
  static const Color outline = Color(0xFF737780);
  static const Color outlineVariant = Color(0xFFC3C6D1);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Member Theme Gradient (Soft Sky/Lavender - Calm & Professional)
  static const LinearGradient memberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F2F1), // Very Pale Teal
      Color(0xFFE3F2FD), // Soft Sky Blue
      Color(0xFFF3E5F5), // Pale Lavender
    ],
  );

  // Reseller Theme Gradient (Soft Mint/Blue - Fresh & Serene)
  static const LinearGradient resellerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF1F8E9), // Pale Mint
      Color(0xFFE0F7FA), // Soft Cyan
      Color(0xFFE1F5FE), // Light Sky Blue
    ],
  );

  static const LinearGradient kineticGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      primaryContainer,
      secondary,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      secondary,
      onSecondaryContainer,
    ],
  );
}
