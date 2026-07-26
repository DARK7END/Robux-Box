import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/admin_providers.dart';

/// Guards admin routes. Renders [child] only when the signed-in user holds the
/// `admin` claim; otherwise shows a loader (while the claim resolves) or an
/// access-denied view. Defence-in-depth only — the real enforcement is in the
/// Cloud Functions (`requireAdmin`) and Firestore rules.
class AdminGate extends ConsumerWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return isAdmin.when(
      loading: () => const AppScaffold(
        title: 'Admin',
        body: PremiumLoadingView(label: 'Checking access…'),
      ),
      error: (_, __) => _denied(context),
      data: (ok) => ok ? child : _denied(context),
    );
  }

  Widget _denied(BuildContext context) {
    return AppScaffold(
      title: 'Admin',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_rounded,
                  size: 56, color: AppColors.danger),
              const SizedBox(height: AppSpacing.lg),
              Text('Admins only',
                  style: context.text.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your account does not have admin access.',
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
