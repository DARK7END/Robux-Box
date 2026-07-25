import 'package:flutter/material.dart';

/// Central color system for Robux Box.
///
/// The palette is inspired by modern gaming UIs (Discord, PlayStation App,
/// Supercell store): deep desaturated backgrounds, a vivid indigo/violet brand
/// core, and neon accents used sparingly for rewards and calls-to-action.
///
/// All colors are defined once here and consumed through [AppTheme]. Never
/// hard-code a hex value inside a widget — add a token here instead.
abstract final class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand core
  // ---------------------------------------------------------------------------
  static const Color brand = Color(0xFF6C5CE7); // indigo-violet
  static const Color brandBright = Color(0xFF8B7CFF);
  static const Color brandDeep = Color(0xFF4B3FCF);
  static const Color secondary = Color(0xFF00D1FF); // cyan glow
  static const Color secondaryDeep = Color(0xFF0091EA);

  // ---------------------------------------------------------------------------
  // Accent / semantic
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF2ED573);
  static const Color successDeep = Color(0xFF12B368);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D6D);
  static const Color dangerDeep = Color(0xFFE23350);
  static const Color info = Color(0xFF41A7FF);

  // Reward accents
  static const Color coin = Color(0xFFFFC531); // gold
  static const Color coinDeep = Color(0xFFF39C12);
  static const Color robux = Color(0xFF00B06D); // robux green
  static const Color vip = Color(0xFFFFD54A);
  static const Color xp = Color(0xFF00E5FF);

  // ---------------------------------------------------------------------------
  // Dark theme surfaces (default)
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF0B0B14);
  static const Color darkBgElevated = Color(0xFF12121F);
  static const Color darkSurface = Color(0xFF181826);
  static const Color darkSurfaceHigh = Color(0xFF1F1F30);
  static const Color darkCard = Color(0xFF1A1A2B);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkDivider = Color(0x14FFFFFF);

  static const Color darkTextPrimary = Color(0xFFF5F6FF);
  static const Color darkTextSecondary = Color(0xFFB4B7CC);
  static const Color darkTextTertiary = Color(0xFF7A7D96);

  // Glassmorphism (dark)
  static const Color glassFillDark = Color(0x1AFFFFFF);
  static const Color glassBorderDark = Color(0x26FFFFFF);
  static const Color glassHighlightDark = Color(0x40FFFFFF);

  // ---------------------------------------------------------------------------
  // Light theme surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBg = Color(0xFFF4F5FB);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFF0F1F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightDivider = Color(0x0F000000);

  static const Color lightTextPrimary = Color(0xFF14142B);
  static const Color lightTextSecondary = Color(0xFF5A5D74);
  static const Color lightTextTertiary = Color(0xFF9296AD);

  // Glassmorphism (light)
  static const Color glassFillLight = Color(0x99FFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassHighlightLight = Color(0xCCFFFFFF);

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color scrim = Color(0x99000000);

  /// A tier-color for ad/geo tiers (T1 highest paying → T4 lowest).
  static Color tierColor(int tier) {
    switch (tier) {
      case 1:
        return success;
      case 2:
        return secondary;
      case 3:
        return warning;
      default:
        return darkTextTertiary;
    }
  }
}
