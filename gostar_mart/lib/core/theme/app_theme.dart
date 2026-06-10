import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.midnightNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.sovereignGold,
        onPrimary: AppColors.midnightNavy,
        primaryContainer: AppColors.surfaceContainerLow,
        onPrimaryContainer: AppColors.sovereignGold,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.surfaceContainer,
        onSecondaryContainer: AppColors.onSurface,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
      ),
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.goldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.sovereignGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: AppColors.onSurfaceVariant,
        suffixIconColor: AppColors.onSurfaceVariant,
      ),
      // ── Elevated Button (Primary) ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sovereignGold,
          foregroundColor: AppColors.midnightNavy,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      // ── Outlined Button (Secondary/Ghost) ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sovereignGold,
          side: const BorderSide(color: AppColors.sovereignGold, width: 1),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      // ── Card ──
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.goldBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedColor: AppColors.sovereignGold.withValues(alpha: 0.15),
        side: const BorderSide(color: AppColors.outlineVariant),
        labelStyle: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0,
      ),
      // ── Text Theme via google_fonts ──
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: AppTextStyles.display.copyWith(color: AppColors.onSurface),
        headlineLarge: AppTextStyles.h1.copyWith(color: AppColors.onSurface),
        headlineMedium: AppTextStyles.h2.copyWith(color: AppColors.onSurface),
        headlineSmall: AppTextStyles.h3.copyWith(color: AppColors.onSurface),
        bodyLarge: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurface),
        bodyMedium: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
        bodySmall: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        labelLarge: AppTextStyles.labelLg.copyWith(color: AppColors.onSurface),
        labelMedium: AppTextStyles.labelMd.copyWith(color: AppColors.onSurface),
        labelSmall: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
