import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Premium typography scale.
///
/// Display/headline styles use "Sora" — a distinctive geometric font — while
/// body/label styles use "Plus Jakarta Sans" for excellent legibility across age
/// groups and scripts. Both are provided by [GoogleFonts] (cached at runtime, or
/// bundle them for offline-first via `google_fonts`' asset workflow).
///
/// Arabic falls back automatically to the platform Arabic font through
/// [GoogleFonts]'s built-in fallback chain; sizing/spacing tokens stay identical
/// so RTL layouts feel native.
abstract final class AppTypography {
  const AppTypography._();

  static TextStyle _display(double size, FontWeight weight, {double? height}) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: -0.5,
    );
  }

  static TextStyle _body(double size, FontWeight weight, {double? height}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: 0.1,
    );
  }

  /// Builds a full Material 3 [TextTheme] for the given base text color.
  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: _display(40, FontWeight.w700, height: 1.1).copyWith(color: primary),
      displayMedium: _display(34, FontWeight.w700, height: 1.12).copyWith(color: primary),
      displaySmall: _display(28, FontWeight.w600, height: 1.15).copyWith(color: primary),
      headlineLarge: _display(26, FontWeight.w600, height: 1.2).copyWith(color: primary),
      headlineMedium: _display(22, FontWeight.w600, height: 1.2).copyWith(color: primary),
      headlineSmall: _display(20, FontWeight.w600, height: 1.25).copyWith(color: primary),
      titleLarge: _body(18, FontWeight.w700, height: 1.3).copyWith(color: primary),
      titleMedium: _body(16, FontWeight.w600, height: 1.35).copyWith(color: primary),
      titleSmall: _body(14, FontWeight.w600, height: 1.4).copyWith(color: primary),
      bodyLarge: _body(16, FontWeight.w500, height: 1.5).copyWith(color: primary),
      bodyMedium: _body(14, FontWeight.w500, height: 1.5).copyWith(color: secondary),
      bodySmall: _body(12, FontWeight.w500, height: 1.45).copyWith(color: secondary),
      labelLarge: _body(14, FontWeight.w700, height: 1.2).copyWith(color: primary),
      labelMedium: _body(12, FontWeight.w600, height: 1.2).copyWith(color: secondary),
      labelSmall: _body(11, FontWeight.w600, height: 1.2).copyWith(color: secondary),
    );
  }

  /// A tabular-figure style for coin/currency counters so digits don't jitter
  /// while animating.
  static TextStyle counter(double size, Color color) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle get brandWordmark => _display(24, FontWeight.w700).copyWith(
        color: AppColors.white,
        letterSpacing: -1,
      );
}
