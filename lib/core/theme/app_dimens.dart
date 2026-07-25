import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing, radius, elevation and motion tokens.
///
/// A single 4px baseline grid keeps the layout rhythmic. Radii are large and
/// rounded to match the "Supercell store / PlayStation app" card language.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double xxl = 32;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(xxl));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}

abstract final class AppDuration {
  const AppDuration._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration counter = Duration(milliseconds: 900);
}

abstract final class AppCurves {
  const AppCurves._();

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
}

/// Soft, layered shadows for elevated cards. Kept subtle so glass surfaces read
/// as premium rather than heavy.
abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.45),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 8),
        ),
      ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 22,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> brandGlow = glow(AppColors.brand);
}
