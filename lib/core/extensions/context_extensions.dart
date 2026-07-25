import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Ergonomic accessors on [BuildContext] for theme, text styles, sizing,
/// localisation and directionality.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;

  AppLocalizations get l10n => AppLocalizations.of(this);

  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  bool get isCompact => MediaQuery.sizeOf(this).width < 400;
}
