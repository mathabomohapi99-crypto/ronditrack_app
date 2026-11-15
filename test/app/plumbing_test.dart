// NEW 10.3: the retry rule and the flavour flag
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/retry.dart';
import 'package:ronditrack/core/config/app_config.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

void main() {
  test('not found is never retried', () {
    expect(appRetry(0, const NotFoundException()), isNull);
    expect(appRetry(5, const NotFoundException()), isNull);
  });

  test('other failures retry with backoff, then stop', () {
    expect(appRetry(0, Exception('boom')), const Duration(milliseconds: 200));
    expect(appRetry(3, Exception('boom')), const Duration(milliseconds: 1600));
    expect(appRetry(9, Exception('boom')), const Duration(milliseconds: 6400));
    expect(appRetry(10, Exception('boom')), isNull);
  });

  test('only the dev flavour is dev', () {
    AppConfig of(String f) => AppConfig.fromValues(
      nativeFlavor: f,
      configFlavor: f,
      apiBaseUrl: 'http://x',
    );
    expect(of('dev').isDev, isTrue);
    expect(of('staging').isDev, isFalse);
    expect(of('prod').isDev, isFalse);
  });
}
