// UPDATED 10.3: same as 10.2 plus isDev, so dev-only code can ask "am I the dev flavour?"
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

  // Only the dev flavour may contain dev-only tools (the persona switcher)
  bool get isDev => flavor == 'dev';

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
