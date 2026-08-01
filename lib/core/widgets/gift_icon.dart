import 'package:flutter/material.dart';

/// The brand's own gift-card mark — a real line-art icon, used everywhere a
/// generic "gift card" glyph is needed in place of the stock Material icon.
/// Drawn as a plain black stroke on a transparent field, so — unlike a full
/// illustration — it's designed to be recoloured: [color] tints the whole
/// shape the same way [Icon]'s `color` would, letting it drop in wherever
/// `Icon(Icons.card_giftcard_rounded, ...)` was used before.
class GiftIcon extends StatelessWidget {
  const GiftIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/gift_outline_icon.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
