import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The brand's own currency mark ("R$"), used everywhere a coin/money glyph
/// is needed in place of a generic dollar-sign icon. Occupies the same
/// `size x size` footprint an [Icon] would, so it drops in as a direct
/// replacement — [FittedBox] scales the mark to fit, so it never overflows
/// a tightly constrained parent.
class RGlyph extends StatelessWidget {
  const RGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          'R\$',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
      ),
    );
  }
}
