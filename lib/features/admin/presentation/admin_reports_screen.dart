import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/model_utils.dart';
import '../domain/admin_providers.dart';

/// Read-only view of user-filed reports for triage.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminReportsProvider);
    return AppScaffold(
      title: 'Reports',
      body: async.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyStateView(
              icon: Icons.flag_rounded,
              title: 'No reports',
              message: 'User reports will appear here for review.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final r = reports[i];
              final createdAt = Parse.toDate(r['createdAt']);
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(Parse.toStr(r['subject'], 'Report'),
                              style: context.text.titleSmall),
                        ),
                        StatusPill(
                          label: Parse.toStr(r['category'], 'other'),
                          color: context.colors.primary,
                          dense: true,
                        ),
                      ],
                    ),
                    if (Parse.toStr(r['message']).isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(Parse.toStr(r['message']),
                          style: context.text.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'from ${Parse.toStr(r['uid']).padRight(6).substring(0, 6)}…'
                      '${createdAt != null ? ' • ${createdAt.toLocal()}' : ''}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
