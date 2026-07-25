import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

enum ToastType { success, error, info, warning }

/// Lightweight toast/snackbar helper with themed variants and haptics.
abstract final class AppToast {
  const AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (color, icon) = switch (type) {
      ToastType.success => (AppColors.success, Icons.check_circle_rounded),
      ToastType.error => (AppColors.danger, Icons.error_rounded),
      ToastType.warning => (AppColors.warning, Icons.warning_rounded),
      ToastType.info => (AppColors.info, Icons.info_rounded),
    };

    switch (type) {
      case ToastType.success:
        HapticFeedback.mediumImpact();
      case ToastType.error:
        HapticFeedback.heavyImpact();
      case ToastType.warning:
      case ToastType.info:
        HapticFeedback.selectionClick();
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);
}
