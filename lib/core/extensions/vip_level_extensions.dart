import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../theme/app_colors.dart';

/// Shared tier presentation (color + label) so every screen that shows a VIP
/// tier — the VIP storefront, admin queues, the purchases log — draws from one
/// place instead of re-deriving it.
extension VipLevelX on VipLevel {
  Color get tierColor => switch (this) {
        VipLevel.bronze => const Color(0xFFCD7F32),
        VipLevel.silver => const Color(0xFFC0C4CE),
        VipLevel.gold => AppColors.coin,
        VipLevel.diamond => AppColors.secondary,
        VipLevel.none => AppColors.darkTextTertiary,
      };

  String get label => name[0].toUpperCase() + name.substring(1);
}
