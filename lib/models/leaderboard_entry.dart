import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// A ranked leaderboard row at `leaderboards/{period}/entries/{uid}`.
/// Aggregated by a scheduled Cloud Function so per-user reads stay cheap.
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.uid,
    required this.rank,
    required this.displayName,
    required this.photoUrl,
    required this.score,
    required this.countryCode,
    required this.vipLevel,
  });

  final String uid;
  final int rank;
  final String displayName;
  final String photoUrl;

  /// Coins earned within the period.
  final int score;
  final String countryCode;
  final String vipLevel;

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: uid,
      rank: Parse.toInt(map['rank']),
      displayName: Parse.toStr(map['displayName'], 'Player'),
      photoUrl: Parse.toStr(map['photoUrl']),
      score: Parse.toInt(map['score']),
      countryCode: Parse.toStr(map['countryCode']),
      vipLevel: Parse.toStr(map['vipLevel'], 'none'),
    );
  }

  factory LeaderboardEntry.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      LeaderboardEntry.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [uid, rank, score];
}
