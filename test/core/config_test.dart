// NEW: proves both refusals: no config, and native flavour != config flavour
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/config/app_config.dart';

void main() {
  test('refuses to start without config', () {
    expect(
      () => AppConfig.fromValues(
        nativeFlavor: 'dev',
        configFlavor: '',
        apiBaseUrl: '',
      ),
      throwsA(isA<ConfigError>()),
    );
  });
  test('refuses a prod build given config/dev.json', () {
    expect(
      () => AppConfig.fromValues(
        nativeFlavor: 'prod',
        configFlavor: 'dev',
        apiBaseUrl: 'http://x',
      ),
      throwsA(isA<ConfigError>()),
    );
  });
  test('accepts matching flavour', () {
    expect(
      AppConfig.fromValues(
        nativeFlavor: 'dev',
        configFlavor: 'dev',
        apiBaseUrl: 'http://x',
      ).flavor,
      'dev',
    );
  });
}
