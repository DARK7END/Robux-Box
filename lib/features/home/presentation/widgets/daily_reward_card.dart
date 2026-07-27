import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../models/app_user.dart';
import '../../../earn/domain/earn_controller.dart';

/// Daily streak reward card. Claims via the server (`claimDailyReward`) so the
/// streak logic and reward table are authoritative.
class DailyRewardCard extends ConsumerStatefulWidget {
  const DailyRewardCard({super.key, required this.user});
  final AppUser user;

  @override
  ConsumerState<DailyRewardCard> createState() => _DailyRewardCardState();
}

class _DailyRewardCardState extends ConsumerState<DailyRewardCard> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    final result = await ref.read(earnControllerProvider.notifier).claimDaily();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final value):
        AppToast.success(
            context, context.l10n.earnRewardCredited(value.coinsCredited));
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextDayIndex =
        widget.user.streakCount % AppConstants.dailyStreakRewards.length;
    final reward = AppConstants.dailyStreakRewards[nextDayIndex];

    return GlassCard(
      gradient: AppGradients.coin,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.redeem_rounded,
                color: AppColors.black, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeDailyReward,
                  style:
                      context.text.titleSmall?.copyWith(color: AppColors.black),
                ),
                Text(
                  '+$reward coins • ${context.l10n.homeStreakDays(widget.user.streakCount)}',
                  style: context.text.bodySmall
                      ?.copyWith(color: Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          GradientButton(
            label: context.l10n.homeClaim,
            gradient: const LinearGradient(
                colors: [AppColors.black, Color(0xFF2A2A2A)]),
            expand: false,
            height: 42,
            glow: false,
            loading: _busy,
            onPressed: _busy ? null : _claim,
          ),
        ],
      ),
    );
  }
}
