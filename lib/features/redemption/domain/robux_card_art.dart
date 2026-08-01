import '../../../models/reward.dart';

/// Bundled card art for the standard global Robux gift-card tiers — real
/// branded artwork, shown in place of the code-drawn coin glyph whenever a
/// reward's face value matches one of these. Keyed by `currency:faceValue`
/// since the catalogue has two parallel tracks (Robux-amount packs priced in
/// "RBX", USD-value packs priced in "USD") whose face values could otherwise
/// collide (e.g. a future 5-Robux pack vs. the $5 card).
const _robuxCardArt = <String, String>{
  'RBX:100': 'assets/images/robux_packages/robux_100.png',
  'RBX:200': 'assets/images/robux_packages/robux_200.png',
  'RBX:400': 'assets/images/robux_packages/robux_400.png',
  'RBX:800': 'assets/images/robux_packages/robux_800.png',
  'RBX:1000': 'assets/images/robux_packages/robux_1000.png',
  'RBX:2500': 'assets/images/robux_packages/robux_2500.png',
  'USD:5': 'assets/images/robux_packages/robux_usd_5.png',
  'USD:10': 'assets/images/robux_packages/robux_usd_10.png',
  'USD:20': 'assets/images/robux_packages/robux_usd_20.png',
};

/// The bundled card art asset path for [reward], or null if it isn't one of
/// the standard tiers above (e.g. a custom admin-added Robux package).
String? robuxCardArtFor(Reward reward) {
  if (reward.kind != RewardKind.robux) return null;
  return _robuxCardArt['${reward.currency}:${reward.faceValue.round()}'];
}
