import 'package:flutter/services.dart' show appFlavor;

enum Flavor { dev, staging, prod }

class ConfigError implements Exception {
  new(this.message);

  final String message;

  @override
  String toString() => 'ConfigError: $message';
}

class AppConfig {
  const new({
    required this.flavor,
    required this.apiBaseUrl,
    required this.refreshCookieName,
  });

  factory fromEnvironment() => AppConfig.resolve(
    flavor: const String.fromEnvironment('FLAVOR'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    refreshCookieName: const String.fromEnvironment('REFRESH_COOKIE_NAME'),
    nativeFlavor: appFlavor,
  );

  /// Pure and testable: validates the dart-define values against the native
  /// flavour the binary was built with.
  factory resolve({
    required String flavor,
    required String apiBaseUrl,
    required String refreshCookieName,
    required String? nativeFlavor,
  }) {
    // UPDATED 11.2: a missing cookie name refuses to start, like a missing base URL
    if (flavor.isEmpty || apiBaseUrl.isEmpty || refreshCookieName.isEmpty) {
      throw ConfigError(
        'No config. Run with --dart-define-from-file=config/<flavor>.json',
      );
    }
    final parsed = Flavor.values.where((f) => f.name == flavor).firstOrNull;
    if (parsed == null) {
      throw ConfigError('Unknown flavor "$flavor" in config.');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme) {
      throw ConfigError('API_BASE_URL is not an absolute URL.');
    }
    if (nativeFlavor != parsed.name) {
      throw ConfigError(
        'Native flavor "$nativeFlavor" does not match config "$flavor". '
        'Use the config file that matches --flavor.',
      );
    }
    return AppConfig(
      flavor: parsed,
      apiBaseUrl: apiBaseUrl,
      refreshCookieName: refreshCookieName,
    );
  }

  final Flavor flavor;
  final String apiBaseUrl;

  /// Never typed into code: comes from config/<flavor>.json
  final String refreshCookieName;

  /// Dev-only tools (the persona switcher). Staging and prod build none.
  bool get devToolsEnabled => flavor == Flavor.dev;
}
