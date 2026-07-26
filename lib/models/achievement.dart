import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// A gamified achievement definition (from `config/achievements`) merged with
/// the user's unlock progress (from `users/{uid}` progress map).
class Achievement extends Equatable {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rewardCoins,
    required this.target,
    required this.progress,
    required this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;

  /// Material icon codepoint name resolved by the UI (kept as a stable key).
  final String icon;
  final int rewardCoins;
  final int target;
  final int progress;
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null || progress >= target;
  double get ratio => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  factory Achievement.fromMap(String id, Map<String, dynamic> map) {
    return Achievement(
      id: id,
      title: Parse.toStr(map['title']),
      description: Parse.toStr(map['description']),
      icon: Parse.toStr(map['icon'], 'star'),
      rewardCoins: Parse.toInt(map['rewardCoins']),
      target: Parse.toInt(map['target'], 1),
      progress: Parse.toInt(map['progress']),
      unlockedAt: Parse.toDate(map['unlockedAt']),
    );
  }

  @override
  List<Object?> get props => [id, progress, unlockedAt];
}
