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

class AdminPromocodesScreen extends ConsumerWidget {
  const AdminPromocodesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPromocodesProvider);
    return AppScaffold(
      title: 'Promocodes',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.black,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _PromoForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New code'),
      ),
      body: async.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (codes) {
          if (codes.isEmpty) {
            return EmptyStateView(
              icon: Icons.confirmation_number_rounded,
              title: 'No promocodes',
              message: 'Create your first promo code with the button below.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + AppSpacing.lg, bottom: 90),
            itemCount: codes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final c = codes[i];
              return GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.code,
                              style: context.text.titleMedium
                                  ?.copyWith(letterSpacing: 2)),
                          Text(
                              '+${c.rewardCoins} coins • '
                              '${c.redemptionCount}${c.maxRedemptions >= 0 ? '/${c.maxRedemptions}' : ''} used',
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: c.isRedeemable ? 'Active' : 'Inactive',
                      color: c.isRedeemable
                          ? AppColors.success
                          : AppColors.darkTextTertiary,
                      dense: true,
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

class _PromoForm extends ConsumerStatefulWidget {
  const _PromoForm();

  @override
  ConsumerState<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends ConsumerState<_PromoForm> {
  final _code = TextEditingController();
  final _coins = TextEditingController(text: '100');
  final _max = TextEditingController(text: '-1');
  final _perUser = TextEditingController(text: '1');
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _coins.dispose();
    _max.dispose();
    _perUser.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final code = _code.text.trim().toUpperCase();
    final coins = int.tryParse(_coins.text.trim()) ?? 0;
    if (code.isEmpty || coins <= 0) {
      AppToast.error(context, 'Enter a code and a positive reward.');
      return;
    }
    setState(() => _busy = true);
    final r = await ref.read(adminRepositoryProvider).upsertPromocode(
          code: code,
          rewardCoins: coins,
          maxRedemptions: int.tryParse(_max.text.trim()) ?? -1,
          perUserLimit: int.tryParse(_perUser.text.trim()) ?? 1,
          isActive: true,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Success():
        Navigator.pop(context);
        AppToast.success(context, 'Promocode saved');
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Text('New promocode', style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Code', hintText: 'WELCOME'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _coins,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reward coins'),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max uses', hintText: '-1 = ∞'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _perUser,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Per user'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          GradientButton(
            label: 'Save promocode',
            loading: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
