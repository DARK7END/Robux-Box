import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/transaction.dart';
import '../../../models/wallet.dart';
import '../../profile/data/user_repository.dart';
import '../data/wallet_repository.dart';

enum _TxFilter { all, earned, spent }

/// Wallet: premium balance hero + filterable transaction ledger.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  _TxFilter _filter = _TxFilter.all;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(currentWalletProvider).valueOrNull ??
        Wallet.empty('');
    final txAsync = ref.watch(transactionsProvider);

    return AppScaffold(
      title: context.l10n.walletTitle,
      body: ListView(
        padding: const EdgeInsets.only(
            top: kToolbarHeight + AppSpacing.md, bottom: 40),
        children: [
          _BalanceHero(wallet: wallet)
              .animate()
              .fadeIn()
              .slideY(begin: 0.1, curve: AppCurves.standard),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: context.l10n.walletEarned,
                  value: wallet.lifetimeEarned,
                  color: AppColors.brand,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  label: context.l10n.walletSpent,
                  value: wallet.lifetimeSpent,
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: SectionHeader(title: context.l10n.walletTransactions)),
              _FilterChips(
                filter: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ],
          ),
          txAsync.when(
            loading: () => Column(
              children: List.generate(
                6,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: ShimmerBox(height: 64, radius: AppRadius.md),
                ),
              ),
            ),
            error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
            data: (txs) {
              final filtered = switch (_filter) {
                _TxFilter.all => txs,
                _TxFilter.earned =>
                  txs.where((t) => t.isCredit).toList(),
                _TxFilter.spent =>
                  txs.where((t) => !t.isCredit).toList(),
              };
              if (filtered.isEmpty) {
                return EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: context.l10n.walletNoTransactions,
                  message: context.l10n.walletNoTransactionsDesc,
                );
              }
              return Column(
                children: filtered
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TransactionTile(tx: e.value)
                              .animate()
                              .fadeIn(delay: (30 * e.key).ms)
                              .slideX(begin: 0.06),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final robux = wallet.coins.asRobux(AppConstants.coinsPerRobux);
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: const IgnorePointer(child: CoinParticles(count: 10)),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.glow(AppColors.brand),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.walletBalance,
                  style: context.text.bodyMedium
                      ?.copyWith(color: Colors.black.withOpacity(0.7))),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const RGlyph(size: 34, color: AppColors.black),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedCounter(
                    value: wallet.coins,
                    style: AppTypography.counter(38, AppColors.black),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text('≈ $robux Robux',
                        style: context.text.labelMedium?.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              if (wallet.pendingCoins > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('${wallet.pendingCoins} coins pending redemption',
                    style: context.text.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.65))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedCounter(
            value: value,
            style: context.text.titleLarge!.copyWith(color: color),
          ),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});
  final _TxFilter filter;
  final ValueChanged<_TxFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = {
      _TxFilter.all: context.l10n.walletAll,
      _TxFilter.earned: context.l10n.walletEarned,
      _TxFilter.spent: context.l10n.walletSpent,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.surfaces.surfaceHigh,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _TxFilter.values.map((f) {
          final active = f == filter;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: AppDuration.fast,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                gradient: active ? AppGradients.brand : null,
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                labels[f]!,
                style: context.text.labelSmall?.copyWith(
                  color:
                      active ? AppColors.black : context.surfaces.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A single ledger row with type icon, title, relative time and signed amount.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx});
  final WalletTransaction tx;

  IconData get _icon => switch (tx.type) {
        TxType.rewardedAd => Icons.play_circle_fill_rounded,
        TxType.offerwall => Icons.assignment_turned_in_rounded,
        TxType.dailyBonus || TxType.streakBonus => Icons.redeem_rounded,
        TxType.referralBonus || TxType.referralShare => Icons.group_rounded,
        TxType.promocode => Icons.confirmation_number_rounded,
        TxType.achievement => Icons.emoji_events_rounded,
        TxType.levelUp => Icons.arrow_upward_rounded,
        TxType.redemption => Icons.card_giftcard_rounded,
        TxType.refund => Icons.replay_rounded,
        TxType.adjustment => Icons.tune_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = tx.isCredit ? AppColors.brand : AppColors.danger;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: tx.type == TxType.redemption
                ? GiftIcon(size: 22, color: color)
                : Icon(_icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title.isNotEmpty ? tx.title : tx.type.name,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (tx.createdAt != null)
                  Text(tx.createdAt!.relative(context.l10n),
                      style: context.text.bodySmall),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'}${tx.amount}',
            style: AppTypography.counter(16, color),
          ),
        ],
      ),
    );
  }
}
