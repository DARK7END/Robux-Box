import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared parsing helpers so every model handles Firestore's loosely-typed
/// `Map<String, dynamic>` data defensively and consistently.
abstract final class Parse {
  const Parse._();

  static int toInt(Object? v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double toDouble(Object? v, [double fallback = 0]) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool toBool(Object? v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static String toStr(Object? v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static DateTime? toDate(Object? v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> toStringList(Object? v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static Map<String, dynamic> toMap(Object? v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return const {};
  }

  static T enumFromName<T extends Enum>(
    Object? v,
    List<T> values,
    T fallback,
  ) {
    final name = v?.toString();
    return values.firstWhere((e) => e.name == name, orElse: () => fallback);
  }
}
