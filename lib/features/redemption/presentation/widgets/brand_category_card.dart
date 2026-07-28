import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/reward_brand.dart';

/// A premium, tappable brand tile (Roblox, Steam, PlayStation…). Brand-coloured
/// gradient, soft glow, glossy highlight and the app-wide [Pressable] squish.
/// The Material [icon] is a placeholder for the official logo PNG the client
/// will drop in later.
class BrandCategoryCard extends StatelessWidget {
  const BrandCategoryCard({super.key, required this.brand, required this.onTap});

  final RewardBrand brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = brand;
    final onColor =
        ThemeData.estimateBrightnessForColor(b.primary) == Brightness.dark
            ? Colors.white
            : AppColors.black;
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: b.gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: b.primary.withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Glossy top highlight.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 26,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'brand_${b.id}',
                    // Renders the official logo once one is dropped into
                    // assets/icons/brands/ and set on the RewardBrand; falls
                    // back to a generic glyph until then.
                    child: b.assetLogo != null
                        ? Image.asset(b.assetLogo!, width: 30, height: 30)
                        : Icon(b.icon, color: onColor, size: 30),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
