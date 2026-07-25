import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'model_utils.dart';

/// Category of an offerwall task, used for filtering and iconography.
enum OfferCategory { survey, game, app, signup, purchase, video, other }

/// An offerwall offer surfaced to the user. Offers are ingested from the
/// provider into `offers/{id}` by a Cloud Function and localised per tier so
/// the displayed reward already reflects the user's geo multiplier.
class Offer extends Equatable {
  const Offer({
    required this.id,
    required this.provider,
    required this.category,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.rewardCoins,
    required this.trackingUrl,
    required this.requirements,
    required this.countries,
    required this.isMultiStep,
    required this.featured,
    required this.expiresAt,
    required this.payoutUsd,
  });

  final String id;
  final String provider;
  final OfferCategory category;
  final String title;
  final String description;
  final String iconUrl;

  /// Coins the user receives on completion (already tier-adjusted server-side).
  final int rewardCoins;

  /// Signed click/tracking URL that carries the user's subid for postback
  /// attribution. Built by the backend, never by the client.
  final String trackingUrl;
  final List<String> requirements;
  final List<String> countries;
  final bool isMultiStep;
  final bool featured;
  final DateTime? expiresAt;

  /// Gross provider payout — used server-side to compute the developer margin;
  /// exposed to the client only for admin views.
  final double payoutUsd;

  factory Offer.fromMap(String id, Map<String, dynamic> map) {
    return Offer(
      id: id,
      provider: Parse.toStr(map['provider']),
      category: Parse.enumFromName(
          map['category'], OfferCategory.values, OfferCategory.other),
      title: Parse.toStr(map['title']),
      description: Parse.toStr(map['description']),
      iconUrl: Parse.toStr(map['iconUrl']),
      rewardCoins: Parse.toInt(map['rewardCoins']),
      trackingUrl: Parse.toStr(map['trackingUrl']),
      requirements: Parse.toStringList(map['requirements']),
      countries: Parse.toStringList(map['countries']),
      isMultiStep: Parse.toBool(map['isMultiStep']),
      featured: Parse.toBool(map['featured']),
      expiresAt: Parse.toDate(map['expiresAt']),
      payoutUsd: Parse.toDouble(map['payoutUsd']),
    );
  }

  factory Offer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Offer.fromMap(doc.id, doc.data() ?? const {});

  @override
  List<Object?> get props => [id, provider, rewardCoins, featured];
}
