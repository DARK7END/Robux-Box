import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_user.dart';
import '../../profile/data/user_repository.dart';
import '../data/vip_repository.dart';

/// Presents the VIP tiers, highlighting the user's current level, and lets
/// them purchase/renew one — Bronze and Silver with coins or real money,
/// Gold and Diamond with real money only (enforced server-side too, in
/// `purchaseVipWithCoins`).
class VipScreen extends ConsumerStatefulWidget {
  const VipScreen({super.key});

  @override
  ConsumerState<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends ConsumerState<VipScreen> {
  static const _tierOrder = [
    VipLevel.bronze,
    VipLevel.silver,
    VipLevel.gold,
    VipLevel.diamond,
  ];

  /// The tier currently mid-purchase, so its buttons show a spinner and every
  /// card's buttons disable (prevents double-taps across tiers too).
  VipLevel? _busy;

  String _label(VipLevel level) =>
      level.name[0].toUpperCase() + level.name.substring(1);

  Future<void> _buyWithCoins(VipLevel level, int price) async {
    final ok = await _confirmCoinsPurchase(level, price);
    if (!ok || !mounted) return;
    final coins = ref.read(currentWalletProvider).valueOrNull?.coins ?? 0;
    if (coins < price) {
      AppToast.error(context, context.l10n.rewardsInsufficient);
      return;
    }
    setState(() => _busy = level);
    final result =
        await ref.read(vipRepositoryProvider).purchaseWithCoins(level);
    if (!mounted) return;
    setState(() => _busy = null);
    switch (result) {
      case Success():
        AppToast.success(
          context,
          context.l10n.vipPurchaseSuccessBody(
              _label(level), AppConstants.vipDurationDays),
        );
      case Err(:final failure):
        AppToast.error(context, failure.message);
    }
  }

  Future<void> _buyWithMoney(VipLevel level) async {
    setState(() => _busy = level);
    final result = await ref.read(vipRepositoryProvider).buyWithMoney(level);
    if (!mounted) return;
    setState(() => _busy = null);
    if (result case Err(:final failure)) {
      AppToast.error(context, failure.message);
    }
    // Success is reported later via vipPurchaseEventsProvider, once the store
    // confirms the purchase and the backend has verified it.
  }

  Future<bool> _confirmCoinsPurchase(VipLevel level, int price) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => _ConfirmDialog(
        title: dialogContext.l10n.vipConfirmCoinsTitle,
        body: dialogContext.l10n.vipConfirmCoinsBody(
            price, _label(level), AppConstants.vipDurationDays),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final current = user?.effectiveVipLevel ?? VipLevel.none;

    ref.listen<AsyncValue<VipPurchaseUpdate>>(vipPurchaseEventsProvider,
        (_, next) {
      final event = next.valueOrNull;
      if (event == null) return;
      switch (event) {
        case VipPurchaseSucceeded(:final level):
          AppToast.success(
            context,
            context.l10n.vipPurchaseSuccessBody(
                _label(level), AppConstants.vipDurationDays),
          );
        case VipPurchaseFailed(:final message):
          AppToast.error(context, message);
      }
    });

    return AppScaffold(
      title: context.l10n.vipTitle,
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          GlassCard(
            gradient: AppGradients.vip,
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.black, size: 48),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.vipSubtitle,
                    style: context.text.titleMedium
                        ?.copyWith(color: AppColors.black),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.vipCurrentTier(_label(current)),
                  style: context.text.bodyMedium
                      ?.copyWith(color: Colors.black.withOpacity(0.7)),
                ),
                if (current != VipLevel.none && user?.vipExpiresAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      context.l10n.vipExpiresInDays(
                        user!.vipExpiresAt!
                            .difference(DateTime.now())
                            .inDays
                            .clamp(0, 999),
                      ),
                      style: context.text.bodySmall
                          ?.copyWith(color: Colors.black.withOpacity(0.6)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._tierOrder.map((tier) {
            final isCurrent = tier == current;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _VipTierCard(
                tier: tier,
                label: _label(tier),
                isCurrent: isCurrent,
                busy: _busy == tier,
                disabled: _busy != null && _busy != tier,
                onBuyWithCoins: (price) => _buyWithCoins(tier, price),
                onBuyWithMoney: () => _buyWithMoney(tier),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VipTierCard extends StatelessWidget {
  const _VipTierCard({
    required this.tier,
    required this.label,
    required this.isCurrent,
    required this.busy,
    required this.disabled,
    required this.onBuyWithCoins,
    required this.onBuyWithMoney,
  });

  final VipLevel tier;
  final String label;
  final bool isCurrent;
  final bool busy;
  final bool disabled;
  final ValueChanged<int> onBuyWithCoins;
  final VoidCallback onBuyWithMoney;

  Color get _color => switch (tier) {
        VipLevel.bronze => const Color(0xFFCD7F32),
        VipLevel.silver => const Color(0xFFC0C4CE),
        VipLevel.gold => AppColors.coin,
        VipLevel.diamond => AppColors.secondary,
        VipLevel.none => AppColors.darkTextTertiary,
      };

  @override
  Widget build(BuildContext context) {
    final multiplier = AppConstants.vipMultipliers[tier.name] ?? 1.0;
    final adLimit = AppConstants.vipMaxAdsPerDay[tier.name] ??
        AppConstants.maxRewardedAdsPerDay;
    final coinPrice = AppConstants.vipCoinPrices[tier.name];
    final moneyPrice = AppConstants.vipMoneyPrices[tier.name] ?? '';

    return GlassCard(
      borderColor: isCurrent ? _color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.military_tech_rounded, color: _color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.text.titleMedium),
                    Text(
                      context.l10n.vipMultiplier(multiplier.toStringAsFixed(2)),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                StatusPill(
                    label: context.l10n.vipActiveLabel,
                    color: _color,
                    filled: true,
                    dense: true)
              else if (coinPrice == null)
                StatusPill(
                  label: context.l10n.vipMoneyOnlyBadge,
                  color: context.surfaces.textTertiary,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _Benefit(
                icon: Icons.smart_display_rounded,
                label: context.l10n.vipAdsPerDay(adLimit),
              ),
              _Benefit(
                icon: Icons.local_fire_department_rounded,
                label: context.l10n.vipOfferAccessDesc,
              ),
              // Real-money-only tiers get fast-tracked support + redemption
              // fulfilment — see requestRedemption's `priority` flag and
              // createTicket's `isPriority` flag.
              if (tier == VipLevel.gold || tier == VipLevel.diamond)
                _Benefit(
                  icon: Icons.star_rounded,
                  label: context.l10n.vipPrioritySupportDesc,
                  color: _color,
                ),
            ],
          ),
          if (!isCurrent) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (coinPrice != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          disabled ? null : () => onBuyWithCoins(coinPrice),
                      child: busy
                          ? PremiumLoader(
                              size: 18, strokeWidth: 2.2, color: _color)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded,
                                    color: AppColors.coin, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    context.l10n.vipBuyCoinsButton(coinPrice),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: GradientButton(
                    label: context.l10n.vipBuyMoneyButton(moneyPrice),
                    gradient: AppGradients.vip,
                    foregroundColor: AppColors.black,
                    loading: busy,
                    enabled: !disabled,
                    onPressed: disabled ? null : onBuyWithMoney,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color ?? context.surfaces.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: context.text.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.commonConfirm),
        ),
      ],
    );
  }
}
