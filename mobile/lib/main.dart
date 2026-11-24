import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/app/config.dart';
import 'package:ronditrack/core/network/dio_provider.dart';
import 'package:ronditrack/core/privacy/error_reporter.dart';
import 'package:ronditrack/core/privacy/scrubber.dart';
import 'package:ronditrack/core/session/session_providers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Empty by default. Each person passes theirs with --dart-define=SENTRY_DSN=..., never committed
const _dsn = String.fromEnvironment('SENTRY_DSN');

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  void start() => runApp(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(config.apiBaseUrl),
        refreshCookieNameProvider.overrideWithValue(config.refreshCookieName),
        if (_dsn.isNotEmpty)
          errorReporterProvider.overrideWithValue(const SentryErrorReporter()),
      ],
      child: RondiTrackApp(config: config),
    ),
  );
  // Without a DSN the app starts exactly as before and nothing is sent
  if (_dsn.isEmpty) {
    start();
    return;
  }
  await SentryFlutter.init((options) {
    options
      ..dsn = _dsn
      ..environment = config.flavor.name
      ..sendDefaultPii = false
      ..beforeSend = (event, hint) => scrubEvent(event);
    // release is left as Sentry builds it (app id, version, build number)
  }, appRunner: start);
}
