import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display - serif (Fraunces) para títulos hero
  static TextStyle get display => GoogleFonts.fraunces(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.05,
        letterSpacing: -1.2,
      );

  static TextStyle get h1 => GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -0.6,
      );

  static TextStyle get h2 => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  // Body - Plus Jakarta Sans
  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        height: 1.2,
        letterSpacing: 1.2,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      );

  // Numérico - tabular para precios y cantidades
  static TextStyle kpiLarge({Color? color}) => GoogleFonts.fraunces(
        fontSize: 38,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -1.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle kpiMedium({Color? color}) => GoogleFonts.fraunces(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
        height: 1.0,
        letterSpacing: -0.8,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle price({Color? color, double size = 16}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -0.2,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: h1,
        displaySmall: h2,
        headlineLarge: h2,
        headlineMedium: h3,
        headlineSmall: h3,
        titleLarge: h3,
        titleMedium: label,
        titleSmall: label,
        bodyLarge: bodyLg,
        bodyMedium: body,
        bodySmall: bodySm,
        labelLarge: label,
        labelMedium: labelSm,
        labelSmall: caption,
      );
}
