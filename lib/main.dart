import 'bootstrap.dart';

/// Application entry point.
///
/// All initialisation lives in [bootstrap] so it can be shared with integration
/// tests and alternative entry points (e.g. flavor-specific `main_prod.dart`).
Future<void> main() => bootstrap();
