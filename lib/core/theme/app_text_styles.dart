import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headlines - Inter, Bold, Italic
  static TextStyle get headline1 => GoogleFonts.inter(
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.textDark,
  );

  static TextStyle get headline2 => GoogleFonts.inter(
    fontSize: 28.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline3 => GoogleFonts.inter(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  // Titles - Inter, Bold, Italic (Slightly smaller)
  static TextStyle get title1 => GoogleFonts.inter(
    fontSize: 22.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.textDark,
  );

  static TextStyle get title2 => GoogleFonts.inter(
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  static TextStyle get title3 => GoogleFonts.inter(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  // Body - Lato, Light (w300)
  static TextStyle get body1 => GoogleFonts.lato(
    fontSize: 16.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
  );

  static TextStyle get body2 => GoogleFonts.lato(
    fontSize: 14.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get body3 => GoogleFonts.lato(
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );

  // Buttons - Lato, Light
  static TextStyle get button => GoogleFonts.lato(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400, // Slightly more legible
    color: AppColors.textPrimary, // Changed from surface to textPrimary
  );
  
  static TextStyle get caption => GoogleFonts.lato(
    fontSize: 12.sp,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );
}
