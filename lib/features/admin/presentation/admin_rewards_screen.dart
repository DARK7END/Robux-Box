import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/reward.dart';
import '../data/admin_repository.dart';
import '../domain/admin_providers.dart';

class AdminRewardsScreen extends ConsumerWidget {
  const AdminRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRewardsProvider);
    return AppScaffold(
      title: 'Rewards catalogue',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.black,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _RewardForm(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New reward'),
      ),
      body: async.when(
        loading: () => const PremiumLoadingView(),
        error: (e, _) => ErrorStateView(message: context.l10n.errorGeneric),
        data: (rewards) {
          if (rewards.isEmpty) {
            return EmptyStateView(
              icon: Icons.card_giftcard_rounded,
              title: 'No rewards yet',
              message: 'Add Robux packages, gift cards and digital codes.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(
                top: kToolbarHeight + AppSpacing.lg, bottom: 90),
            itemCount: rewards.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final r = rewards[i];
              return GlassCard(
                child: Row(
                  children: [
                    switch (r.kind) {
                      RewardKind.robux =>
                        const RGlyph(size: 24, color: AppColors.robux),
                      RewardKind.giftCard => const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.robux),
                      RewardKind.digitalCode =>
                        const Icon(Icons.vpn_key_rounded, color: AppColors.robux),
                    },
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: context.text.titleSmall),
                          Text('${r.coinCost} coins • ${r.kind.name}',
                              style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    Switch(
                      value: r.isActive,
                      activeColor: AppColors.brand,
                      onChanged: (v) => ref
                          .read(adminRepositoryProvider)
                          .setRewardActive(r.id, v),
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

class _RewardForm extends ConsumerStatefulWidget {
  const _RewardForm();

  @override
  ConsumerState<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends ConsumerState<_RewardForm> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _cost = TextEditingController();
  final _face = TextEditingController();
  final _currency = TextEditingController(text: 'USD');
  final _provider = TextEditingController(text: 'manual');
  final _sort = TextEditingController(text: '100');
  RewardKind _kind = RewardKind.robux;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _cost, _face, _currency, _provider, _sort]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final cost = int.tryParse(_cost.text.trim()) ?? 0;
    if (_title.text.trim().isEmpty || cost <= 0) {
      AppToast.error(context, 'Enter a title and a positive coin cost.');
      return;
    }
    setState(() => _busy = true);
    final data = <String, dynamic>{
      'kind': _kind.name,
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'imageUrl': '',
      'coinCost': cost,
      'faceValue': double.tryParse(_face.text.trim()) ?? 0,
      'currency': _currency.text.trim().toUpperCase(),
      'provider': _provider.text.trim(),
      'stock': -1,
      'isActive': true,
      'minVipLevel': 0,
      'sortOrder': int.tryParse(_sort.text.trim()) ?? 100,
      'badge': '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final r = await ref.read(adminRepositoryProvider).saveReward(null, data);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (r) {
      case Success():
        Navigator.pop(context);
        AppToast.success(context, 'Reward added');
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New reward', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<RewardKind>(
              segments: const [
                ButtonSegment(value: RewardKind.robux, label: Text('Robux')),
                ButtonSegment(value: RewardKind.giftCard, label: Text('Gift')),
                ButtonSegment(value: RewardKind.digitalCode, label: Text('Code')),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _subtitle,
                decoration: const InputDecoration(labelText: 'Subtitle')),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Coin cost'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _face,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Face value'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _provider,
                    decoration: const InputDecoration(labelText: 'Provider'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _sort,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sort'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            GradientButton(
              label: 'Add reward',
              loading: _busy,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
