import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/reward.dart';
import '../../../profile/data/user_repository.dart';
import '../../data/redemption_repository.dart';
import '../../domain/robux_card_art.dart';

/// Bottom sheet to confirm a redemption and collect the delivery target.
Future<void> showRedeemSheet(
  BuildContext context, {
  required Reward reward,
  required int coins,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) =>
        _RedeemSheet(reward: reward, coins: coins, hostContext: context),
  );
}

class _RedeemSheet extends ConsumerStatefulWidget {
  const _RedeemSheet({
    required this.reward,
    required this.coins,
    required this.hostContext,
  });
  final Reward reward;
  final int coins;
  final BuildContext hostContext;

  @override
  ConsumerState<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends ConsumerState<_RedeemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _target;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _target = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  // Every reward kind is fulfilled manually (Robux included — see
  // scripts/seed.js's `provider: "manual"`), so delivery is always to an
  // email an admin can reach, never a Roblox username.
  (String, String?, TextInputType, String? Function(String?)) get _fieldSpec {
    return (
      context.l10n.authEmail,
      'you@example.com',
      TextInputType.emailAddress,
      Validators.email,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.coins < widget.reward.coinCost) {
      AppToast.error(context, context.l10n.rewardsInsufficient);
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(redemptionRepositoryProvider).requestRedemption(
          rewardId: widget.reward.id,
          deliveryTarget: _target.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        final host = widget.hostContext;
        final title = context.l10n.rewardsSubmittedTitle;
        final message = context.l10n.rewardsRequestSubmitted;
        Navigator.of(context).pop();
        if (host.mounted) {
          await showCelebration(
            host,
            title: title,
            message: message,
            icon: Icons.card_giftcard_rounded,
          );
        }
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, hint, keyboard, validator) = _fieldSpec;
    final affordable = widget.coins >= widget.reward.coinCost;
    final localArt = robuxCardArtFor(widget.reward);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: context.viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'reward_${widget.reward.id}',
              child: Container(
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: switch (widget.reward.kind) {
                    RewardKind.robux => AppGradients.robux,
                    RewardKind.giftCard => AppGradients.neon,
                    RewardKind.digitalCode => AppGradients.vip,
                  },
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                // A known Robux tier's real card art takes priority over the
                // generic glyph, matching the reward card it Hero-animates from.
                // This banner is much wider (and thus more tightly cropped
                // vertically) than the reward card's art panel, so it needs a
                // lower focal point to keep the package number in frame.
                child: localArt != null
                    ? Image.asset(localArt,
                        fit: BoxFit.cover, alignment: const Alignment(0, -0.5))
                    : switch (widget.reward.kind) {
                        RewardKind.robux =>
                          const RGlyph(size: 44, color: AppColors.white),
                        RewardKind.giftCard => const Icon(
                            Icons.card_giftcard_rounded,
                            color: AppColors.white,
                            size: 44),
                        RewardKind.digitalCode => const Icon(
                            Icons.vpn_key_rounded,
                            color: AppColors.white,
                            size: 44),
                      },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.l10n.rewardsConfirmTitle,
                style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.rewardsConfirmBody(
                  widget.reward.title, widget.reward.coinCost),
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _target,
              keyboardType: keyboard,
              decoration: InputDecoration(labelText: label, hintText: hint),
              validator: validator,
            ),
            const SizedBox(height: AppSpacing.lg),
            _CostRow(
                cost: widget.reward.coinCost,
                balance: widget.coins,
                affordable: affordable),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              label: context.l10n.rewardsRedeem,
              icon: Icons.redeem_rounded,
              loading: _busy,
              enabled: affordable,
              onPressed: affordable && !_busy ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.cost,
    required this.balance,
    required this.affordable,
  });
  final int cost;
  final int balance;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceHigh,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n.rewardsCostLabel, style: context.text.bodyMedium),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 18),
              const SizedBox(width: 4),
              Text('$cost',
                  style: context.text.titleSmall?.copyWith(
                    color: affordable ? null : AppColors.danger,
                  )),
              const SizedBox(width: AppSpacing.sm),
              Text('(balance $balance)', style: context.text.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
