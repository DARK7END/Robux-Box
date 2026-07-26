import 'package:flutter/material.dart';

import '../../../models/reward.dart';

/// A redeemable brand shown as a premium category card on the Redeem screen.
///
/// Colours mirror each brand's identity; [icon] is a Material placeholder that
/// the client can swap for the official logo PNG/SVG later (drop it in
/// `assets/icons/brands/` and set [assetLogo]). [match] decides which catalogue
/// [Reward]s belong to this brand (by kind + provider/title keyword).
class RewardBrand {
  const RewardBrand({
    required this.id,
    required this.name,
    required this.colors,
    required this.icon,
    required this.kind,
    this.keyword,
    this.assetLogo,
  });

  final String id;
  final String name;
  final List<Color> colors;
  final IconData icon;
  final RewardKind kind;

  /// Optional keyword matched against reward title/provider (case-insensitive).
  final String? keyword;

  /// Optional bundled logo asset path (placeholder for now).
  final String? assetLogo;

  Gradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

  Color get primary => colors.first;

  bool matches(Reward r) {
    if (r.kind != kind) return false;
    if (keyword == null) return true;
    final k = keyword!.toLowerCase();
    return r.title.toLowerCase().contains(k) ||
        r.provider.toLowerCase().contains(k) ||
        r.subtitle.toLowerCase().contains(k);
  }
}

/// The nine premium brands from the reference, in display order.
abstract final class RewardBrands {
  const RewardBrands._();

  static const roblox = RewardBrand(
    id: 'roblox',
    name: 'Roblox',
    colors: [Color(0xFF00FF6A), Color(0xFF00A344)],
    icon: Icons.videogame_asset_rounded,
    kind: RewardKind.robux,
  );

  static const steam = RewardBrand(
    id: 'steam',
    name: 'Steam',
    colors: [Color(0xFF66C0F4), Color(0xFF1B2838)],
    icon: Icons.cloud_rounded,
    kind: RewardKind.giftCard,
    keyword: 'steam',
  );

  static const playstation = RewardBrand(
    id: 'playstation',
    name: 'PlayStation',
    colors: [Color(0xFF2E6FF2), Color(0xFF00439C)],
    icon: Icons.sports_esports_rounded,
    kind: RewardKind.giftCard,
    keyword: 'playstation',
  );

  static const xbox = RewardBrand(
    id: 'xbox',
    name: 'Xbox',
    colors: [Color(0xFF3BE277), Color(0xFF107C10)],
    icon: Icons.gamepad_rounded,
    kind: RewardKind.giftCard,
    keyword: 'xbox',
  );

  static const nintendo = RewardBrand(
    id: 'nintendo',
    name: 'Nintendo',
    colors: [Color(0xFFFF4B4B), Color(0xFFE60012)],
    icon: Icons.sports_esports_outlined,
    kind: RewardKind.giftCard,
    keyword: 'nintendo',
  );

  static const googlePlay = RewardBrand(
    id: 'google_play',
    name: 'Google Play',
    colors: [Color(0xFFFFD84D), Color(0xFFF5A600)],
    icon: Icons.play_arrow_rounded,
    kind: RewardKind.digitalCode,
    keyword: 'google',
  );

  static const apple = RewardBrand(
    id: 'apple',
    name: 'Apple',
    colors: [Color(0xFFE6E8EA), Color(0xFF9AA0A6)],
    icon: Icons.apple,
    kind: RewardKind.digitalCode,
    keyword: 'apple',
  );

  static const amazon = RewardBrand(
    id: 'amazon',
    name: 'Amazon',
    colors: [Color(0xFFFFB84D), Color(0xFFFF9900)],
    icon: Icons.shopping_cart_rounded,
    kind: RewardKind.giftCard,
    keyword: 'amazon',
  );

  static const paypal = RewardBrand(
    id: 'paypal',
    name: 'PayPal',
    colors: [Color(0xFF3B9BE2), Color(0xFF003087)],
    icon: Icons.account_balance_wallet_rounded,
    kind: RewardKind.giftCard,
    keyword: 'paypal',
  );

  static const List<RewardBrand> all = [
    roblox,
    steam,
    playstation,
    xbox,
    nintendo,
    googlePlay,
    apple,
    amazon,
    paypal,
  ];
}
