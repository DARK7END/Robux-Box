import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/earn_controller.dart';
import 'spin_wheel.dart';

/// Opens the daily Spin Wheel as a modal. The backend decides the prize; the
/// wheel animates to land on exactly that segment, then celebrates.
Future<void> showSpinWheelSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SpinSheet(),
  );
}

class _SpinSheet extends ConsumerStatefulWidget {
  const _SpinSheet();

  @override
  ConsumerState<_SpinSheet> createState() => _SpinSheetState();
}

class _SpinSheetState extends ConsumerState<_SpinSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  Animation<double>? _anim;
  double _rotation = 0;
  bool _spinning = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();

    final result = await ref.read(earnControllerProvider.notifier).playSpin();
    if (!mounted) return;

    switch (result) {
      case Success(:final value):
        final index = value.prizeIndex ?? 0;
        await _animateTo(index);
        if (!mounted) return;
        setState(() => _spinning = false);
        Navigator.of(context).maybePop();
        await showCelebration(
          context,
          title: 'You won!',
          message: 'Added to your balance. Come back tomorrow for another spin!',
          coins: value.coinsCredited,
          icon: Icons.casino_rounded,
        );
      case Err(:final Failure failure):
        setState(() => _spinning = false);
        AppToast.error(context, failure.message);
    }
  }

  Future<void> _animateTo(int index) async {
    final n = AppConstants.spinWheelPrizes.length;
    final seg = 2 * math.pi / n;
    final currentNorm = _rotation % (2 * math.pi);
    final desiredNorm = (2 * math.pi - index * seg) % (2 * math.pi);
    final delta = (desiredNorm - currentNorm) % (2 * math.pi);
    final target = _rotation + 6 * 2 * math.pi + delta;

    _anim = Tween<double>(begin: _rotation, end: target).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutQuart),
    )..addListener(() => setState(() => _rotation = _anim!.value));
    _c.reset();
    await _c.forward();
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
          Text('Spin & Win', style: context.text.headlineSmall),
          Text('One free spin every day',
              style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.xxl),
          SpinWheel(
            prizes: AppConstants.spinWheelPrizes,
            rotation: _rotation,
            size: MediaQuery.sizeOf(context).width * 0.72,
          ),
          const SizedBox(height: AppSpacing.xxl),
          GradientButton(
            label: _spinning ? 'Spinning…' : 'SPIN',
            icon: _spinning ? null : Icons.casino_rounded,
            loading: _spinning,
            onPressed: _spinning ? null : _spin,
          ),
        ],
      ),
    );
  }
}
