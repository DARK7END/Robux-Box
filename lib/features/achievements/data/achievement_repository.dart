import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/achievement.dart';

/// Reads the user's achievement progress (`users/{uid}/achievements`), which the
/// backend keeps in sync as milestones are reached.
class AchievementRepository {
  AchievementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Achievement>> watch(String uid) {
    return _firestore
        .collection(FsPaths.users)
        .doc(uid)
        .collection('achievements')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Achievement.fromMap(d.id, d.data()))
            .toList());
  }
}

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(firestoreProvider));
});

final achievementsProvider = StreamProvider<List<Achievement>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const []);
  return ref.watch(achievementRepositoryProvider).watch(auth.uid);
});
