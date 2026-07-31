import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/earn_controller.dart';

/// Daily Lucky Chest — an animated chest that shakes invitingly and bursts open
/// on tap, awarding a server-decided prize.
Future<void> showLuckyChestSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChestSheet(),
  );
}

class _ChestSheet extends ConsumerStatefulWidget {
  const _ChestSheet();

  @override
  ConsumerState<_ChestSheet> createState() => _ChestSheetState();
}

class _ChestSheetState extends ConsumerState<_ChestSheet> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    HapticFeedback.heavyImpact();
    final result = await ref.read(earnControllerProvider.notifier).playChest();
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(:final value):
        final title = context.l10n.earnChestWonTitle;
        final message = context.l10n.earnChestWinMessage;
        Navigator.of(context).maybePop();
        await showCelebration(
          context,
          title: title,
          message: message,
          coins: value.coinsCredited,
          icon: Icons.inventory_2_rounded,
        );
      case Err(:final Failure failure):
        AppToast.error(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaces.background,
        borderRadius: AppRadius.sheetRadius,
        border: Border.all(color: context.surfaces.glassBorder),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: context.padding.bottom + AppSpacing.xl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.surfaces.border,
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(context.l10n.earnLuckyChestName, style: context.text.headlineSmall),
          Text(context.l10n.earnLuckyChestOpenDesc,
              style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.xxl),
          _Chest(busy: _busy),
          const SizedBox(height: AppSpacing.xxl),
          GradientButton(
            label: _busy ? 'Opening…' : 'OPEN CHEST',
            gradient: AppGradients.coin,
            foregroundColor: AppColors.black,
            icon: _busy ? null : Icons.lock_open_rounded,
            loading: _busy,
            onPressed: _busy ? null : _open,
          ),
        ],
      ),
    );
  }
}

class _Chest extends StatelessWidget {
  const _Chest({required this.busy});
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final chest = Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        gradient: AppGradients.coin,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.coin.withOpacity(0.5),
            blurRadius: 44,
            spreadRadius: -6,
          ),
        ],
      ),
      child: const Icon(Icons.inventory_2_rounded,
          size: 84, color: AppColors.black),
    );

    if (busy) {
      return chest
          .animate(onPlay: (c) => c.repeat())
          .shake(hz: 6, curve: Curves.easeInOut, duration: 500.ms);
    }
    return chest
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut)
        .shimmer(
            duration: 2000.ms, color: Colors.white.withOpacity(0.4));
  }
}
