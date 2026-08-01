import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/extensions/vip_level_extensions.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

/// Every VIP subscription ever bought — coins or real money, any tier —
/// newest first. The one place an admin can audit who bought what and how.
class AdminVipPurchasesScreen extends ConsumerWidget {
  const AdminVipPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(adminVipPurchasesProvider);

    return AppScaffold(
      title: 'VIP Purchases',
      body: records.isEmpty
          ? const EmptyStateView(
              icon: Icons.workspace_premium_rounded,
              title: 'No purchases yet',
              message: 'Coin and real-money VIP purchases will show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(
                  top: kToolbarHeight + AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xl),
              itemCount: records.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => _PurchaseTile(record: records[i]),
            ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.record});
  final VipPurchaseRecord record;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: record.level.tierColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(Icons.military_tech_rounded,
                color: record.level.tierColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: record.level.label,
                      color: record.level.tierColor,
                      dense: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      record.isMoneyPurchase
                          ? Icons.credit_card_rounded
                          : Icons.bolt_rounded,
                      size: 14,
                      color: context.surfaces.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(record.detail,
                          style: context.text.labelMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  record.uid.length >= 8
                      ? '${record.uid.substring(0, 8)}…'
                      : record.uid,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          if (record.createdAt != null)
            Text(record.createdAt!.relative(context.l10n),
                style: context.text.labelSmall),
        ],
      ),
    );
  }
}
