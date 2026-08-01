import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/redemption.dart';
import '../data/redemption_repository.dart';

/// Redemption history with pending / approved / rejected filters.
class RedemptionsScreen extends ConsumerWidget {
  const RedemptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(redemptionsProvider);
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: context.l10n.redemptionTitle,
        body: Column(
          children: [
            SizedBox(height: kToolbarHeight + context.padding.top),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: context.l10n.commonSeeAll),
                Tab(text: context.l10n.redemptionPending),
                Tab(text: context.l10n.redemptionApproved),
                Tab(text: context.l10n.redemptionRejected),
              ],
            ),
            Expanded(
              child: async.when(
                loading: () => const PremiumLoadingView(),
                error: (e, _) =>
                    ErrorStateView(message: context.l10n.errorGeneric),
                data: (items) => TabBarView(
                  children: [
                    _List(items: items),
                    _List(
                        items: items
                            .where((r) => r.status == RedemptionStatus.pending)
                            .toList()),
                    _List(
                        items: items
                            .where((r) =>
                                r.status == RedemptionStatus.approved ||
                                r.status == RedemptionStatus.paid)
                            .toList()),
                    _List(
                        items: items
                            .where((r) =>
                                r.status == RedemptionStatus.rejected ||
                                r.status == RedemptionStatus.cancelled)
                            .toList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});
  final List<Redemption> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_rounded,
        title: context.l10n.redemptionEmpty,
        message: context.l10n.redemptionEmptyDesc,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _RedemptionTile(redemption: items[i]),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  const _RedemptionTile({required this.redemption});
  final Redemption redemption;

  (Color, String) _status(BuildContext context) {
    return switch (redemption.status) {
      RedemptionStatus.pending => (
          AppColors.warning,
          context.l10n.redemptionStatusPending
        ),
      RedemptionStatus.approved => (
          AppColors.info,
          context.l10n.redemptionStatusApproved
        ),
      RedemptionStatus.paid => (
          AppColors.success,
          context.l10n.redemptionStatusPaid
        ),
      RedemptionStatus.rejected => (
          AppColors.danger,
          context.l10n.redemptionStatusRejected
        ),
      RedemptionStatus.cancelled => (AppColors.darkTextTertiary, 'Cancelled'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _status(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(redemption.title, style: context.text.titleSmall),
              ),
              StatusPill(label: label, color: color, dense: true),
            ],
          ),
          if (redemption.priority) ...[
            const SizedBox(height: 4),
            StatusPill(
              label: context.l10n.redemptionPriorityLabel,
              color: AppColors.secondary,
              icon: Icons.star_rounded,
              dense: true,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.coin, size: 16),
              const SizedBox(width: 4),
              Text('${redemption.coinCost}', style: context.text.bodySmall),
              const Spacer(),
              if (redemption.createdAt != null)
                Text(redemption.createdAt!.relative(context.l10n),
                    style: context.text.bodySmall),
            ],
          ),
          if (redemption.status == RedemptionStatus.paid &&
              redemption.deliveredCode.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: AppRadius.cardRadius,
              ),
              child: SelectableText(
                redemption.deliveredCode,
                style:
                    context.text.titleSmall?.copyWith(color: AppColors.success),
              ),
            ),
          ],
          if (redemption.status == RedemptionStatus.rejected &&
              redemption.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(redemption.rejectionReason,
                style:
                    context.text.bodySmall?.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}
