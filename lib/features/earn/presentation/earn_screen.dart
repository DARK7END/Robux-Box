import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../profile/data/user_repository.dart';
import '../domain/earn_controller.dart';
import 'widgets/earn_reward_dialog.dart';

/// The Earn hub: watch rewarded ads and open the offerwall.
class EarnScreen extends ConsumerStatefulWidget {
  const EarnScreen({super.key});

  @override
  ConsumerState<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends ConsumerState<EarnScreen> {
  bool _watching = false;

  Future<void> _watchAd() async {
    if (_watching) return;
    setState(() => _watching = true);
    final result =
        await ref.read(earnControllerProvider.notifier).watchRewardedAd();
    if (!mounted) return;
    setState(() => _watching = false);
    switch (result) {
      case Success(:final value):
        await showEarnRewardDialog(context, coins: value.coinsCredited);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(currentWalletProvider);
    final adReady = ref.watch(adReadyProvider).valueOrNull ?? false;
    final wallet = walletAsync.valueOrNull;
    final adsLeft = wallet == null
        ? AppConstants.maxRewardedAdsPerDay
        : (AppConstants.maxRewardedAdsPerDay - wallet.adsWatchedToday)
            .clamp(0, AppConstants.maxRewardedAdsPerDay);

    return AppScaffold(
      title: context.l10n.earnTitle,
      body: ListView(
        padding: const EdgeInsets.only(
            top: kToolbarHeight + AppSpacing.lg, bottom: 110),
        children: [
          _WatchAdCard(
            ready: adReady,
            watching: _watching,
            adsLeft: adsLeft,
            maxCoins: (AppConstants.baseRewardedAdCoins *
                    (wallet == null ? 1 : 1))
                .toInt(),
            onWatch: adsLeft > 0 ? _watchAd : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          _OfferwallCard(onOpen: () => context.push(AppRoutes.offerwall)),
          const SizedBox(height: AppSpacing.lg),
          _PromoCodeCard(),
        ],
      ),
    );
  }
}

class _WatchAdCard extends StatelessWidget {
  const _WatchAdCard({
    required this.ready,
    required this.watching,
    required this.adsLeft,
    required this.maxCoins,
    required this.onWatch,
  });

  final bool ready;
  final bool watching;
  final int adsLeft;
  final int maxCoins;
  final VoidCallback? onWatch;

  @override
  Widget build(BuildContext context) {
    final limitReached = adsLeft <= 0;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.white, size: 32),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.earnWatchAds,
                        style: context.text.titleMedium),
                    Text(context.l10n.earnWatchAdsDesc(maxCoins),
                        style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.earnDailyLimit(
                  AppConstants.maxRewardedAdsPerDay - adsLeft,
                  AppConstants.maxRewardedAdsPerDay,
                ),
                style: context.text.bodySmall,
              ),
              if (!limitReached)
                StatusPill(
                  label: ready
                      ? context.l10n.earnAdReady
                      : context.l10n.earnAdLoading,
                  color: ready ? AppColors.success : AppColors.warning,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            label: limitReached
                ? context.l10n.earnLimitReached
                : context.l10n.homeWatchAd,
            icon: limitReached ? Icons.lock_clock_rounded : Icons.play_arrow_rounded,
            loading: watching,
            enabled: !limitReached && onWatch != null,
            onPressed: onWatch,
          ),
        ],
      ),
    );
  }
}

class _OfferwallCard extends StatelessWidget {
  const _OfferwallCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.neon,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: AppColors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.earnOfferwall,
                    style: context.text.titleMedium),
                Text(context.l10n.earnOfferwallDesc,
                    style: context.text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        ],
      ),
    );
  }
}

class _PromoCodeCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PromoCodeCard> createState() => _PromoCodeCardState();
}

class _PromoCodeCardState extends ConsumerState<_PromoCodeCard> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    final result =
        await ref.read(earnControllerProvider.notifier).redeemPromocode(code);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final value):
        _controller.clear();
        AppToast.success(
            context, context.l10n.earnRewardCredited(value.coinsCredited));
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_rounded,
                  color: AppColors.coin),
              const SizedBox(width: AppSpacing.sm),
              Text('Promo code', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'ENTER CODE'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GradientButton(
                label: context.l10n.rewardsRedeem,
                expand: false,
                height: 48,
                loading: _busy,
                onPressed: _busy ? null : _redeem,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
