import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.dmSans(
      fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
      fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get titleLarge => GoogleFonts.dmSans(
      fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static TextStyle get titleMedium => GoogleFonts.dmSans(
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
      fontSize: 16, color: AppColors.textPrimary);

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
      fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get bodySmall => GoogleFonts.dmSans(
      fontSize: 12, color: AppColors.textMuted);

  static TextStyle get labelSmall => GoogleFonts.dmSans(
      fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5);

  static TextStyle get labelCaps => GoogleFonts.dmSans(
      fontSize: 10, fontWeight: FontWeight.w600,
      color: AppColors.textMuted, letterSpacing: 1.0);

  static TextStyle get metricValue => GoogleFonts.dmSans(
      fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get ringValue => GoogleFonts.dmSans(
      fontSize: 42, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get statusBadge => GoogleFonts.dmSans(
      fontSize: 12, fontWeight: FontWeight.w500);
}
