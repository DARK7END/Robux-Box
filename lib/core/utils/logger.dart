import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger. In release builds only warnings and above are emitted, and
/// they are also forwarded to Crashlytics (wired up in bootstrap).
final AppLogger log = AppLogger._();

class AppLogger {
  AppLogger._();

  final Logger _logger = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 100,
      colors: !kReleaseMode,
      printEmojis: true,
    ),
  );

  void d(Object? message) => _logger.d(message);
  void i(Object? message) => _logger.i(message);
  void w(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  void e(Object? message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
