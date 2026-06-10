import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // === Display / Hero (Noto Serif) ===
  static TextStyle get display => GoogleFonts.notoSerif(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.96,
      );

  // === Headlines (Noto Serif) ===
  static TextStyle get h1 => GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get h2 => GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get h3 => GoogleFonts.notoSerif(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // === Body (Manrope) ===
  static TextStyle get bodyLg => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySm => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // === Labels & Captions (Manrope) ===
  static TextStyle get labelLg => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.2,
      );

  static TextStyle get labelMd => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.96,
        height: 1.2,
      );

  static TextStyle get labelSm => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.2,
      );

  // === Price / Accent ===
  static TextStyle get price => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.2,
      );

  static TextStyle get priceLg => GoogleFonts.notoSerif(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.1,
      );

  // === Button Text ===
  static TextStyle get button => GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        height: 1.2,
      );
}
