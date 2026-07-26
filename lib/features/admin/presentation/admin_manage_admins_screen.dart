import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

/// Grant or revoke the `admin` custom claim by email, and list current admins.
class AdminManageAdminsScreen extends ConsumerStatefulWidget {
  const AdminManageAdminsScreen({super.key});

  @override
  ConsumerState<AdminManageAdminsScreen> createState() =>
      _AdminManageAdminsScreenState();
}

class _AdminManageAdminsScreenState
    extends ConsumerState<AdminManageAdminsScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _set(bool grant) async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      AppToast.error(context, 'Enter an email.');
      return;
    }
    setState(() => _busy = true);
    final r = await ref.read(adminRepositoryProvider).setAdmin(email, grant);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Success():
        _email.clear();
        AppToast.success(context, grant ? 'Admin granted' : 'Admin revoked');
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admins = ref.watch(adminsProvider);
    return AppScaffold(
      title: 'Manage admins',
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Grant or revoke access', style: context.text.titleSmall),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Grant',
                        icon: Icons.add_moderator_rounded,
                        loading: _busy,
                        onPressed: () => _set(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _set(false),
                        icon: const Icon(Icons.remove_moderator_rounded,
                            color: AppColors.danger),
                        label: const Text('Revoke',
                            style: TextStyle(color: AppColors.danger)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Current admins'),
          admins.when(
            loading: () => const PremiumLoadingView(),
            error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
            data: (list) {
              if (list.isEmpty) {
                return EmptyStateView(
                  icon: Icons.shield_rounded,
                  title: 'No admins listed',
                  message: 'Granted admins will appear here.',
                );
              }
              return Column(
                children: list
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_rounded,
                                    color: AppColors.brand, size: 20),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text('${a['email'] ?? a['uid']}',
                                      style: context.text.titleSmall),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () {
                                          _email.text =
                                              (a['email'] ?? '').toString();
                                          _set(false);
                                        },
                                  child: const Text('Revoke',
                                      style:
                                          TextStyle(color: AppColors.danger)),
                                ),
                              ],
                            ),
                          ),
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
