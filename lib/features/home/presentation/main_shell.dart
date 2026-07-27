import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';

/// Root scaffold hosting the five primary tabs with a floating, glassmorphic
/// bottom bar. The selected tab is marked by a glowing pill that springs into
/// place, and the active icon lifts with a subtle bounce.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // Home · Earn · Redeem · Tasks · Profile
  static const _items = [
    _NavItem(Icons.home_rounded, Icons.home_outlined),
    _NavItem(Icons.bolt_rounded, Icons.bolt_outlined),
    _NavItem(Icons.card_giftcard_rounded, Icons.card_giftcard_outlined),
    _NavItem(Icons.checklist_rounded, Icons.checklist_outlined),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded),
  ];

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.navHome,
      context.l10n.navEarn,
      context.l10n.navRewards, // "Redeem"
      context.l10n.navTasks,
      context.l10n.navProfile,
    ];
    final current = navigationShell.currentIndex;
    final count = _items.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: context.padding.bottom > 0
              ? context.padding.bottom
              : AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: context.surfaces.glassFill,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: context.surfaces.glassBorder),
                boxShadow: AppShadows.elevated,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sliding glow indicator behind the active tab.
                  AnimatedAlign(
                    alignment: Alignment(-1 + 2 * current / (count - 1), 0),
                    duration: AppDuration.medium,
                    curve: AppCurves.spring,
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      child: Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.brand.withOpacity(0.32),
                                AppColors.brand.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(count, (i) {
                      return Expanded(
                        child: _NavButton(
                          item: _items[i],
                          label: labels[i],
                          active: current == i,
                          onTap: () => _onTap(i),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.active, this.inactive);
  final IconData active;
  final IconData inactive;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppColors.brand : context.surfaces.textTertiary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active icon lifts + scales with a spring; inactive sits flat.
          AnimatedSlide(
            offset: Offset(0, active ? -0.06 : 0),
            duration: AppDuration.medium,
            curve: AppCurves.spring,
            child: AnimatedScale(
              scale: active ? 1.16 : 1.0,
              duration: AppDuration.medium,
              curve: AppCurves.spring,
              child: Icon(active ? item.active : item.inactive,
                  color: color, size: 24),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: AppDuration.fast,
            style: context.text.labelSmall!.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
