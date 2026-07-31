import 'package:flutter/material.dart';

/// The brand's own currency mark — a fixed piece of artwork, used everywhere
/// a coin/money glyph is needed in place of a generic dollar-sign icon.
/// Occupies the same `size x size` footprint an [Icon] would, so it drops in
/// as a direct replacement. Being a real image rather than rendered text, its
/// shape never shifts with locale or font fallback.
///
/// [color]'s opacity (not its hue — the artwork is already fully branded) is
/// applied on top, so call sites that pass a translucent color for a faint
/// "ghost" watermark effect keep working unchanged.
class RGlyph extends StatelessWidget {
  const RGlyph({super.key, required this.size, required this.color});

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
          'assets/images/currency_coin.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
