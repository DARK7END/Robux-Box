import 'package:intl/intl.dart';

/// Number, currency and date formatting helpers, locale-aware via [intl].
extension NumFormatX on num {
  /// `1234567` → `1,234,567` (grouping localised).
  String compactGroup([String? locale]) =>
      NumberFormat.decimalPattern(locale).format(this);

  /// `1234567` → `1.2M` for compact chips.
  String compactShort([String? locale]) =>
      NumberFormat.compact(locale: locale).format(this);

  /// Coins → Robux display, e.g. 250 coins / 100 = "2.50".
  String asRobux(int coinsPerRobux) =>
      (this / coinsPerRobux).toStringAsFixed(2);
}

/// Short "in Xh / in Ym" string until the next local midnight — used for daily
/// game (spin/chest) cooldown badges.
String timeUntilMidnight() {
  final now = DateTime.now();
  final next = DateTime(now.year, now.month, now.day + 1);
  final d = next.difference(now);
  if (d.inHours >= 1) return 'in ${d.inHours}h';
  return 'in ${d.inMinutes.clamp(1, 59)}m';
}

/// ISO 3166-1 alpha-2 → flag emoji, e.g. "US" → 🇺🇸. Computed from Unicode
/// Regional Indicator Symbols (base 0x1F1E6 = 'A'), so no lookup table or
/// asset is needed for any of the ~250 country codes.
extension CountryCodeX on String {
  String get flagEmoji {
    final code = trim().toUpperCase();
    if (code.length != 2) return '🏳️';
    final chars = code.codeUnits.map((c) => 0x1F1E6 + (c - 0x41));
    if (chars.any((c) => c < 0x1F1E6 || c > 0x1F1FF)) return '🏳️';
    return String.fromCharCodes(chars);
  }
}

extension DateFormatX on DateTime {
  String relative([DateTime? now]) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(this);
  }

  String get dayMonth => DateFormat.MMMd().format(this);
  String get full => DateFormat.yMMMd().add_jm().format(this);
}
