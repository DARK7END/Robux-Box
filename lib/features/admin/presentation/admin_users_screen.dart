import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/app_user.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  bool _searching = false;
  AdminUserBundle? _found;
  String? _notFound;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final email = _search.text.trim();
    if (email.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _found = null;
      _notFound = null;
    });
    final result = await ref.read(adminRepositoryProvider).findUserByEmail(email);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _found = result;
      _notFound = result == null ? 'No user with that email.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(adminRecentUsersProvider);
    return AppScaffold(
      title: 'Users',
      body: ListView(
        padding: const EdgeInsets.only(top: kToolbarHeight + AppSpacing.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _run(),
                  decoration: const InputDecoration(
                    hintText: 'Search by email',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GradientButton(
                label: 'Find',
                expand: false,
                height: 52,
                loading: _searching,
                onPressed: _run,
              ),
            ],
          ),
          if (_notFound != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(_notFound!,
                  style: context.text.bodyMedium
                      ?.copyWith(color: AppColors.danger)),
            ),
          if (_found != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _UserResultCard(
                bundle: _found!, onChanged: () => setState(() {})),
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Recent sign-ups'),
          recent.when(
            loading: () => const PremiumLoadingView(),
            error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
            data: (users) => Column(
              children: users
                  .map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GlassCard(
                          onTap: () async {
                            final b = await ref
                                .read(adminRepositoryProvider)
                                .getUser(u.uid);
                            if (b != null && context.mounted) {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => _UserActionsSheet(bundle: b),
                              );
                            }
                          },
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: context.colors.primary
                                    .withOpacity(0.2),
                                child: Text(
                                    u.displayName.isNotEmpty
                                        ? u.displayName[0].toUpperCase()
                                        : '?',
                                    style: context.text.labelLarge),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.displayName,
                                        style: context.text.titleSmall),
                                    Text(u.email,
                                        style: context.text.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              StatusPill(
                                label: u.status.name,
                                color: u.status == AccountStatus.active
                                    ? AppColors.success
                                    : AppColors.danger,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({required this.bundle, required this.onChanged});
  final AdminUserBundle bundle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final u = bundle.user;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(u.displayName, style: context.text.titleMedium)),
              StatusPill(
                label: u.status.name,
                color: u.status == AccountStatus.active
                    ? AppColors.success
                    : AppColors.danger,
                dense: true,
              ),
            ],
          ),
          Text(u.email, style: context.text.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _stat(context, 'Coins', '${bundle.wallet.coins}'),
              _stat(context, 'Lifetime', '${bundle.wallet.lifetimeEarned}'),
              _stat(context, 'VIP', u.vipLevel.name),
              _stat(context, 'Tier', 'T${u.tierLevel}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            label: 'Manage user',
            icon: Icons.tune_rounded,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _UserActionsSheet(bundle: bundle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value, style: context.text.titleSmall),
            Text(label, style: context.text.labelSmall),
          ],
        ),
      );
}

class _UserActionsSheet extends ConsumerStatefulWidget {
  const _UserActionsSheet({required this.bundle});
  final AdminUserBundle bundle;

  @override
  ConsumerState<_UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends ConsumerState<_UserActionsSheet> {
  final _amount = TextEditingController();
  final _reason = TextEditingController(text: 'Manual adjustment');
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _do(Future<Result<void>> Function() action, String ok) async {
    setState(() => _busy = true);
    final r = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Success():
        AppToast.success(context, ok);
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminRepositoryProvider);
    final uid = widget.bundle.user.uid;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: context.viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Manage ${widget.bundle.user.displayName}',
              style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          Text('Adjust coins', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: const InputDecoration(hintText: '+100 or -50'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GradientButton(
                label: 'Apply',
                expand: false,
                height: 52,
                loading: _busy,
                onPressed: () {
                  final amount = int.tryParse(_amount.text.trim());
                  if (amount == null || amount == 0) {
                    AppToast.error(context, 'Enter a non-zero amount.');
                    return;
                  }
                  _do(() => repo.adjustCoins(uid, amount, _reason.text.trim()),
                      'Balance updated');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('VIP level', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: VipLevel.values
                .map((v) => ActionChip(
                      label: Text(v.name),
                      onPressed: _busy
                          ? null
                          : () => _do(() => repo.setVipLevel(uid, v.name),
                              'VIP set to ${v.name}'),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Account status', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final s in AccountStatus.values)
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: ActionChip(
                    label: Text(s.name),
                    onPressed: _busy
                        ? null
                        : () => _do(() => repo.setAccountStatus(uid, s.name),
                            'Status: ${s.name}'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
