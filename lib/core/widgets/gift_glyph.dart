import 'package:flutter/material.dart';

/// A gift-box emblem — real artwork used wherever a "gift" glyph replaces a
/// generic present icon (gift-card rewards, redemption confirmations).
/// Occupies the same `size x size` footprint an [Icon] would, so it drops in
/// as a direct replacement.
///
/// [color]'s opacity (not its hue — the artwork is already fully coloured) is
/// applied on top, so call sites that pass a translucent color for a faint
/// "ghost" watermark effect keep working unchanged.
class GiftGlyph extends StatelessWidget {
  const GiftGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Opacity(
        opacity: color.opacity,
        child: Image.asset(
          'assets/images/gift_icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
