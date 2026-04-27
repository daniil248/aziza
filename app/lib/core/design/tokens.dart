import 'package:flutter/material.dart';

/// Aziza Food design tokens.
/// Single source of truth — change here, propagates everywhere.
abstract final class AppColors {
  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF5F5F5);
  static const divider = Color(0xFFEAEAEA);

  // Text
  static const textPrimary = Color(0xFF2C2C2C);
  static const textSecondary = Color(0xFF7A7A7A);
  static const textTertiary = Color(0xFFB5B5B5);

  // Accent (gold)
  static const gold = Color(0xFFD4AF37);
  static const goldPressed = Color(0xFFB5942C);
  static const goldSoft = Color(0xFFFAF1D6);

  // Premium dark (subscription screen)
  static const premiumBg = Color(0xFF1A1A1A);
  static const premiumSurface = Color(0xFF252525);
  static const premiumText = Color(0xFFFFFFFF);

  // States
  static const success = Color(0xFF4A7C59);
  static const warning = Color(0xFFC77C2D);
  static const error = Color(0xFFA23E3E);
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
  static const cubicEmphasized = Cubic(0.2, 0, 0, 1);
}
