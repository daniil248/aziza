import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Inter typography scale per design spec.
abstract final class AppTypography {
  static TextStyle display(Color color) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle title(Color color) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle subtitle(Color color) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle body(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color,
      );

  static TextStyle small(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  static TextStyle caption(Color color) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle button(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.1,
        color: color,
      );
}

extension AppTextStyles on BuildContext {
  TextStyle get display => AppTypography.display(AppColors.textPrimary);
  TextStyle get title => AppTypography.title(AppColors.textPrimary);
  TextStyle get subtitle => AppTypography.subtitle(AppColors.textPrimary);
  TextStyle get body => AppTypography.body(AppColors.textPrimary);
  TextStyle get bodyMuted => AppTypography.body(AppColors.textSecondary);
  TextStyle get small => AppTypography.small(AppColors.textPrimary);
  TextStyle get smallMuted => AppTypography.small(AppColors.textSecondary);
  TextStyle get caption => AppTypography.caption(AppColors.textSecondary);
}
