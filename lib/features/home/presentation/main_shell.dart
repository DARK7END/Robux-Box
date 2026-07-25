import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';

/// Root scaffold hosting the five primary tabs with a floating, glassmorphic
/// bottom navigation bar. Uses a [StatefulNavigationShell] so each tab keeps its
/// own navigation stack and scroll position.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (_NavItem(Icons.home_rounded, Icons.home_outlined)),
    (_NavItem(Icons.bolt_rounded, Icons.bolt_outlined)),
    (_NavItem(Icons.card_giftcard_rounded, Icons.card_giftcard_outlined)),
    (_NavItem(Icons.leaderboard_rounded, Icons.leaderboard_outlined)),
    (_NavItem(Icons.person_rounded, Icons.person_outline_rounded)),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
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
      context.l10n.navRewards,
      context.l10n.navLeaderboard,
      context.l10n.navProfile,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: context.padding.bottom > 0 ? context.padding.bottom : AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: context.surfaces.glassFill,
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: context.surfaces.glassBorder),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final active = navigationShell.currentIndex == i;
                  return Expanded(
                    child: _NavButton(
                      item: _items[i],
                      label: labels[i],
                      active: active,
                      onTap: () => _onTap(i),
                    ),
                  );
                }),
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
        active ? context.colors.primary : context.surfaces.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1.1 : 1.0,
            duration: AppDuration.fast,
            curve: AppCurves.spring,
            child: Icon(active ? item.active : item.inactive,
                color: color, size: 25),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
