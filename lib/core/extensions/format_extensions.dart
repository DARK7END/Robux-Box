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
