import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/redemption.dart';
import '../../../models/reward.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

/// The payout queue: pending / approved / paid / rejected, with approve, reject
/// and mark-paid actions. Every action calls `processRedemption` (which moves
/// held coins and notifies the user).
class AdminRedemptionsScreen extends ConsumerWidget {
  const AdminRedemptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Withdraw requests',
        body: Column(
          children: [
            SizedBox(height: kToolbarHeight + context.padding.top),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Paid'),
                Tab(text: 'Rejected'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _Queue(status: RedemptionStatus.pending),
                  _Queue(status: RedemptionStatus.approved),
                  _Queue(status: RedemptionStatus.paid),
                  _Queue(status: RedemptionStatus.rejected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({required this.status});
  final RedemptionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRedemptionsProvider(status));
    return async.when(
      loading: () => const PremiumLoadingView(),
      error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
      data: (items) {
        if (items.isEmpty) {
          return EmptyStateView(
            icon: Icons.inbox_rounded,
            title: 'Nothing here',
            message: 'No ${status.name} requests.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _RedemptionCard(redemption: items[i]),
        );
      },
    );
  }
}

class _RedemptionCard extends ConsumerStatefulWidget {
  const _RedemptionCard({required this.redemption});
  final Redemption redemption;

  @override
  ConsumerState<_RedemptionCard> createState() => _RedemptionCardState();
}

class _RedemptionCardState extends ConsumerState<_RedemptionCard> {
  bool _busy = false;

  Future<void> _act(String action, {String code = '', String reason = ''}) async {
    setState(() => _busy = true);
    final result = await ref.read(adminRepositoryProvider).processRedemption(
          widget.redemption.id,
          action,
          code: code,
          reason: reason,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success():
        AppToast.success(context, 'Done');
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  Future<void> _markPaid() async {
    final controller = TextEditingController();
    final isCode = widget.redemption.kind != RewardKind.robux;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCode ? 'Deliver code' : 'Confirm payout'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isCode ? 'Gift card / digital code' : 'Reference (optional)',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Mark paid')),
        ],
      ),
    );
    if (code == null) return;
    if (isCode && code.isEmpty) {
      if (mounted) AppToast.error(context, 'A code is required.');
      return;
    }
    await _act('paid', code: code);
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject & refund'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Reason (shown to user)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null) return;
    await _act('reject', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.redemption;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(r.title, style: context.text.titleSmall)),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.coin, size: 16),
                  const SizedBox(width: 3),
                  Text('${r.coinCost}', style: context.text.labelMedium),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: context.surfaces.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    '${r.deliveryTarget}  •  '
                    '${r.uid.length >= 6 ? r.uid.substring(0, 6) : r.uid}…',
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (r.createdAt != null)
                Text(r.createdAt!.relative(), style: context.text.labelSmall),
            ],
          ),
          if (r.status == RedemptionStatus.pending ||
              r.status == RedemptionStatus.approved) ...[
            const SizedBox(height: AppSpacing.md),
            if (_busy)
              const Center(child: PremiumLoader(size: 26))
            else
              Row(
                children: [
                  if (r.status == RedemptionStatus.pending)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _act('approve'),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Approve'),
                      ),
                    ),
                  if (r.status == RedemptionStatus.pending)
                    const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GradientButton(
                      label: 'Mark paid',
                      height: 44,
                      glow: false,
                      onPressed: _markPaid,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _reject,
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.danger),
                    style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.danger.withValues(alpha: 0.12)),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
