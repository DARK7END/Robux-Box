import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/model_utils.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final r = await ref.read(adminRepositoryProvider).refreshAnalytics();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r case Err(:final Failure failure)) {
      AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(analyticsProvider);
    return AppScaffold(
      title: 'Analytics',
      actions: [
        IconButton(
          onPressed: _busy ? null : _refresh,
          icon: _busy
              ? const PremiumLoader(size: 20)
              : const Icon(Icons.refresh_rounded),
        ),
      ],
      body: async.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (m) {
          if (m == null) {
            return EmptyStateView(
              icon: Icons.insights_rounded,
              title: 'No data yet',
              message: 'Tap refresh to compute the first analytics snapshot.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }
          final coins = Parse.toInt(m['coinsInCirculation']);
          final robux = coins.asRobux(AppConstants.coinsPerRobux);
          final updated = DateTime.fromMillisecondsSinceEpoch(
              Parse.toInt(m['updatedAt']));
          final tiles = [
            _Metric('Users', Parse.toInt(m['userCount']).compactGroup(),
                Icons.people_alt_rounded, AppColors.secondary),
            _Metric('Active (24h)', Parse.toInt(m['dau']).compactGroup(),
                Icons.bolt_rounded, AppColors.brand),
            _Metric('Coins in circulation', coins.compactShort(),
                Icons.monetization_on_rounded, AppColors.coin),
            _Metric('≈ Robux liability', robux,
                Icons.paid_rounded, AppColors.robux),
            _Metric('Lifetime earned',
                Parse.toInt(m['lifetimeEarned']).compactShort(),
                Icons.trending_up_rounded, AppColors.success),
            _Metric('Lifetime spent',
                Parse.toInt(m['lifetimeSpent']).compactShort(),
                Icons.trending_down_rounded, AppColors.danger),
          ];

          return ListView(
            padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.5,
                children: tiles
                    .asMap()
                    .entries
                    .map((e) => _MetricCard(metric: e.value)
                        .animate()
                        .fadeIn(delay: (40 * e.key).ms)
                        .slideY(begin: 0.1))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: 'Payouts', icon: Icons.savings_rounded),
              GlassCard(
                child: Column(
                  children: [
                    _row(context, 'Pending requests',
                        '${Parse.toInt(m['pendingRedemptions'])}',
                        color: AppColors.warning),
                    const Divider(height: AppSpacing.xl),
                    _row(context, 'Paid redemptions',
                        '${Parse.toInt(m['paidRedemptions'])}'),
                    const Divider(height: AppSpacing.xl),
                    _row(context, 'Coins paid out',
                        Parse.toInt(m['payoutCoins']).compactGroup()),
                    const Divider(height: AppSpacing.xl),
                    _row(context, 'Payout value',
                        '\$${Parse.toDouble(m['payoutValue']).toStringAsFixed(2)}',
                        color: AppColors.brand),
                    const Divider(height: AppSpacing.xl),
                    _row(context, 'Coins held (pending)',
                        Parse.toInt(m['pendingCoins']).compactGroup()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text('Updated ${updated.relative()}',
                    style: context.text.labelSmall),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.text.bodyMedium),
        Text(value,
            style: context.text.titleSmall?.copyWith(color: color)),
      ],
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(metric.icon, color: metric.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.value,
                  style: AppTypography.counter(22, context.colors.onSurface)),
              Text(metric.label,
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}
