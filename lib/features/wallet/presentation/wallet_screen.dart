import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/transaction.dart';
import '../../profile/data/user_repository.dart';
import '../data/wallet_repository.dart';

/// Wallet: current balance summary and the transaction ledger.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(currentWalletProvider).valueOrNull;
    final txAsync = ref.watch(transactionsProvider);

    return AppScaffold(
      title: context.l10n.walletTitle,
      body: ListView(
        padding: const EdgeInsets.only(
            top: kToolbarHeight + AppSpacing.lg, bottom: 40),
        children: [
          if (wallet != null)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: context.l10n.walletEarned,
                    value: wallet.lifetimeEarned,
                    color: AppColors.success,
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
            ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: context.l10n.walletTransactions),
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
              if (txs.isEmpty) {
                return EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: context.l10n.walletNoTransactions,
                  message: context.l10n.walletNoTransactionsDesc,
                );
              }
              return Column(
                children: txs
                    .map((tx) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: TransactionTile(tx: tx),
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
          Icon(icon, color: color, size: 22),
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
    final color = tx.isCredit ? AppColors.success : AppColors.danger;
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_icon, color: color, size: 22),
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
                  Text(tx.createdAt!.relative(),
                      style: context.text.bodySmall),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'}${tx.amount}',
            style: context.text.titleSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
