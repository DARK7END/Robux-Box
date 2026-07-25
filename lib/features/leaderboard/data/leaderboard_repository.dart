import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/leaderboard_entry.dart';

enum LeaderboardPeriod { daily, weekly, allTime }

extension LeaderboardPeriodX on LeaderboardPeriod {
  String get docId => switch (this) {
        LeaderboardPeriod.daily => 'daily',
        LeaderboardPeriod.weekly => 'weekly',
        LeaderboardPeriod.allTime => 'all_time',
      };
}

/// Reads pre-aggregated leaderboard rows (built by a scheduled function).
class LeaderboardRepository {
  LeaderboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<LeaderboardEntry>> watch(LeaderboardPeriod period) {
    return _firestore
        .collection(FsPaths.leaderboards)
        .doc(period.docId)
        .collection('entries')
        .orderBy('rank')
        .limit(AppConstants.leaderboardPageSize)
        .snapshots()
        .map((snap) => snap.docs.map(LeaderboardEntry.fromDoc).toList());
  }

  Future<LeaderboardEntry?> myEntry(
      LeaderboardPeriod period, String uid) async {
    final doc = await _firestore
        .collection(FsPaths.leaderboards)
        .doc(period.docId)
        .collection('entries')
        .doc(uid)
        .get();
    return doc.exists ? LeaderboardEntry.fromDoc(doc) : null;
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(ref.watch(firestoreProvider));
});

final leaderboardProvider =
    StreamProvider.family<List<LeaderboardEntry>, LeaderboardPeriod>(
        (ref, period) {
  return ref.watch(leaderboardRepositoryProvider).watch(period);
});
