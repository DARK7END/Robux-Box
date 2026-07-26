import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/offer.dart';

/// Reads offerwall offers ingested into the `offers` collection. The full,
/// live wall is still opened as a WebView (Tasks → "More offers"); this list
/// surfaces curated/featured offers natively for a premium in-app feel.
class OffersRepository {
  OffersRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Offer>> watchOffers({OfferCategory? category}) {
    Query<Map<String, dynamic>> query = _firestore.collection(FsPaths.offers);
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    return query
        .orderBy('featured', descending: true)
        .orderBy('rewardCoins', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(Offer.fromDoc).toList());
  }
}

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  return OffersRepository(ref.watch(firestoreProvider));
});

final offersProvider =
    StreamProvider.family<List<Offer>, OfferCategory?>((ref, category) {
  return ref.watch(offersRepositoryProvider).watchOffers(category: category);
});
