import 'package:flutter/material.dart';

/// Central color system for Robux Box.
///
/// Brand kit (per the official reference): a vivid **green** core (`#00E65C`)
/// on near-**black** surfaces (`#0D0D0D` / `#1A1A1A`), with **gold** (`#FFD700`)
/// for coins/rewards and white for text. This is the "gaming rewards" look:
/// dark, neon-green, premium.
///
/// All colors are defined once here and consumed through [AppTheme]. Never
/// hard-code a hex value inside a widget — add a token here instead.
abstract final class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand core — green
  // ---------------------------------------------------------------------------
  static const Color brand = Color(0xFF00E65C); // signature green
  static const Color brandBright = Color(0xFF4DFF91);
  static const Color brandDeep = Color(0xFF00A344);

  // Gold is the secondary accent (coins pair with the green).
  static const Color secondary = Color(0xFFFFD700); // gold
  static const Color secondaryDeep = Color(0xFFF5B800);

  // ---------------------------------------------------------------------------
  // Accent / semantic
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF00E676);
  static const Color successDeep = Color(0xFF00B85C);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4D5E);
  static const Color dangerDeep = Color(0xFFE23350);
  static const Color info = Color(0xFF2ED0FF);

  // Reward accents
  static const Color coin = Color(0xFFFFD700); // gold
  static const Color coinDeep = Color(0xFFF5A600);
  static const Color robux = Color(0xFF00E65C); // robux green
  static const Color vip = Color(0xFFFFD54A);
  static const Color xp = Color(0xFF4DFF91);

  // ---------------------------------------------------------------------------
  // Dark theme surfaces (default) — near-black
  // ---------------------------------------------------------------------------
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkBgElevated = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceHigh = Color(0xFF242424);
  static const Color darkCard = Color(0xFF161616);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkDivider = Color(0x14FFFFFF);

  static const Color darkTextPrimary = Color(0xFFF5F7F5);
  static const Color darkTextSecondary = Color(0xFFB0B4B0);
  static const Color darkTextTertiary = Color(0xFF74786F);

  // Glassmorphism (dark)
  static const Color glassFillDark = Color(0x14FFFFFF);
  static const Color glassBorderDark = Color(0x24FFFFFF);
  static const Color glassHighlightDark = Color(0x38FFFFFF);

  // ---------------------------------------------------------------------------
  // Light theme surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBg = Color(0xFFF3F6F3);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFEDF1ED);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightDivider = Color(0x0F000000);

  static const Color lightTextPrimary = Color(0xFF0D0D0D);
  static const Color lightTextSecondary = Color(0xFF55605A);
  static const Color lightTextTertiary = Color(0xFF8B948C);

  // Glassmorphism (light)
  static const Color glassFillLight = Color(0x99FFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassHighlightLight = Color(0xCCFFFFFF);

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0D0D0D);
  static const Color pureBlack = Color(0xFF000000);
  static const Color scrim = Color(0xCC000000);

  /// A tier-color for ad/geo tiers (T1 highest paying → T4 lowest).
  static Color tierColor(int tier) {
    switch (tier) {
      case 1:
        return brand;
      case 2:
        return secondary;
      case 3:
        return warning;
      default:
        return darkTextTertiary;
    }
  }
}
