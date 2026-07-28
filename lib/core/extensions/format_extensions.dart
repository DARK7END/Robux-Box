import 'package:intl/intl.dart';

import '../l10n/gen/app_localizations.dart';

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
String timeUntilMidnight(AppLocalizations l10n) {
  final now = DateTime.now();
  final next = DateTime(now.year, now.month, now.day + 1);
  final d = next.difference(now);
  if (d.inHours >= 1) return l10n.timeInHours(d.inHours);
  return l10n.timeInMinutes(d.inMinutes.clamp(1, 59).toInt());
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
  String relative(AppLocalizations l10n, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(this);
    if (diff.inSeconds < 60) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat.yMMMd().format(this);
  }

  String get dayMonth => DateFormat.MMMd().format(this);
  String get full => DateFormat.yMMMd().add_jm().format(this);
}
