// NEW: reads --dart-define-from-file values; refuses to start without config or when native flavour != config flavour
import 'package:flutter/services.dart' show appFlavor;

class ConfigError implements Exception {
  const new(this.message);
  final String message;
  @override
  String toString() => 'ConfigError: $message';
}

class AppConfig {
  const new({required this.flavor, required this.apiBaseUrl});
  final String flavor;
  final String apiBaseUrl;

  // Pure function so a unit test can prove both refusals
  static AppConfig fromValues({
    required String? nativeFlavor,
    required String configFlavor,
    required String apiBaseUrl,
  }) {
    if (configFlavor.isEmpty || apiBaseUrl.isEmpty) {
      throw const ConfigError(
        'Missing config. Run with --dart-define-from-file=config/<flavor>.json',
      );
    }
    if (nativeFlavor != configFlavor) {
      throw ConfigError(
        'Native flavour "$nativeFlavor" does not match config "$configFlavor"',
      );
    }
    return AppConfig(flavor: configFlavor, apiBaseUrl: apiBaseUrl);
  }

  static AppConfig load() => fromValues(
    nativeFlavor: appFlavor,
    configFlavor: const String.fromEnvironment('FLAVOR'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
  );
}
