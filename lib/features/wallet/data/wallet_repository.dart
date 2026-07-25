import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/transaction.dart';

/// Reads the immutable transaction ledger (`users/{uid}/transactions`).
class WalletRepository {
  WalletRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _txQuery(String uid) => _firestore
      .collection(FsPaths.users)
      .doc(uid)
      .collection(FsPaths.userTransactions)
      .orderBy('createdAt', descending: true);

  Stream<List<WalletTransaction>> watchTransactions(String uid) {
    return _txQuery(uid)
        .limit(AppConstants.transactionsPageSize)
        .snapshots()
        .map((snap) => snap.docs.map(WalletTransaction.fromDoc).toList());
  }

  /// Cursor-based pagination for the full history screen.
  Future<List<WalletTransaction>> fetchPage(
    String uid, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = AppConstants.transactionsPageSize,
  }) async {
    var query = _txQuery(uid).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    return snap.docs.map(WalletTransaction.fromDoc).toList();
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(firestoreProvider));
});

final transactionsProvider = StreamProvider<List<WalletTransaction>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const []);
  return ref.watch(walletRepositoryProvider).watchTransactions(auth.uid);
});
