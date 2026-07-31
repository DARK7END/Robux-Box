import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable gradients used across cards, buttons and backgrounds.
///
/// Built from the green + gold brand kit: brand actions are green, coins/rewards
/// are gold, and the ambient background glows green over near-black.
abstract final class AppGradients {
  const AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandBright, AppColors.brand, AppColors.brandDeep],
    stops: [0.0, 0.55, 1.0],
  );

  // Gold → green premium sweep (used on secondary CTAs / offerwall).
  static const LinearGradient neon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.brand],
  );

  // Purple accent sweep (missions / play-games / XP).
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), AppColors.accent, AppColors.accentDeep],
  );

  static const LinearGradient coin = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.coin, AppColors.coinDeep],
  );

  static const LinearGradient robux = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandBright, AppColors.brandDeep],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.success, AppColors.successDeep],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.danger, AppColors.dangerDeep],
  );

  static const LinearGradient vip = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE178), AppColors.vip, Color(0xFFF6A609)],
  );

  /// Ambient full-screen background for the dark theme — green glows over the
  /// pure-black base.
  static const RadialGradient ambientDark = RadialGradient(
    center: Alignment(-0.8, -1.0),
    radius: 1.6,
    colors: [Color(0x3300FF6A), Color(0x1A00C853), Color(0x00000000)],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient ambientDarkSecondary = RadialGradient(
    center: Alignment(1.0, -0.3),
    radius: 1.3,
    colors: [Color(0x228B5CF6), Color(0x00000000)],
  );

  static const RadialGradient ambientLight = RadialGradient(
    center: Alignment(-0.8, -1.0),
    radius: 1.6,
    colors: [Color(0x4400FF6A), Color(0x2200C853), Color(0x00000000)],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient ambientLightSecondary = RadialGradient(
    center: Alignment(1.0, -0.2),
    radius: 1.3,
    colors: [Color(0x2600FF6A), Color(0x00000000)],
  );

  /// A shimmering sweep used for premium/VIP highlights and loading states.
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)],
    stops: [0.35, 0.5, 0.65],
  );
}
