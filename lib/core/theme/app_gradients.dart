import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Reusable gradients used across cards, buttons and backgrounds.
abstract final class AppGradients {
  const AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandBright, AppColors.brand, AppColors.brandDeep],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient neon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.brand],
  );

  static const LinearGradient coin = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.coin, AppColors.coinDeep],
  );

  static const LinearGradient robux = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17E88F), AppColors.robux],
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

  /// Ambient full-screen background for the dark theme — a subtle multi-stop
  /// mesh built from radial glows layered over the base background.
  static const RadialGradient ambientDark = RadialGradient(
    center: Alignment(-0.8, -1.0),
    radius: 1.6,
    colors: [Color(0x336C5CE7), Color(0x0000D1FF), Color(0x00000000)],
    stops: [0.0, 0.5, 1.0],
  );

  static const RadialGradient ambientDarkSecondary = RadialGradient(
    center: Alignment(1.0, -0.4),
    radius: 1.3,
    colors: [Color(0x2600D1FF), Color(0x00000000)],
  );

  static const RadialGradient ambientLight = RadialGradient(
    center: Alignment(-0.8, -1.0),
    radius: 1.6,
    colors: [Color(0x1F6C5CE7), Color(0x0000D1FF), Color(0x00000000)],
  );

  /// A shimmering sweep used for premium/VIP highlights and loading states.
  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0x00FFFFFF), Color(0x40FFFFFF), Color(0x00FFFFFF)],
    stops: [0.35, 0.5, 0.65],
  );
}
