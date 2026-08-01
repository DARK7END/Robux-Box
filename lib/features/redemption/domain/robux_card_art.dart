import '../../../models/reward.dart';

/// Bundled card art for the standard global Robux gift-card tiers — real
/// branded artwork, shown in place of the code-drawn coin glyph whenever a
/// reward's face value matches one of these.
const _robuxCardArt = <int, String>{
  100: 'assets/images/robux_packages/robux_100.png',
  200: 'assets/images/robux_packages/robux_200.png',
  400: 'assets/images/robux_packages/robux_400.png',
  800: 'assets/images/robux_packages/robux_800.png',
  1000: 'assets/images/robux_packages/robux_1000.png',
  2500: 'assets/images/robux_packages/robux_2500.png',
};

/// The bundled card art asset path for [reward], or null if it isn't one of
/// the standard tiers above (e.g. a custom admin-added Robux package).
String? robuxCardArtFor(Reward reward) {
  if (reward.kind != RewardKind.robux) return null;
  return _robuxCardArt[reward.faceValue.round()];
}
