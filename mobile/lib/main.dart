import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/app/config.dart';
import 'package:ronditrack/core/network/dio_provider.dart';
import 'package:ronditrack/core/session/session_providers.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(
    ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(config.apiBaseUrl),
        refreshCookieNameProvider.overrideWithValue(config.refreshCookieName),
      ],
      child: RondiTrackApp(config: config),
    ),
  );
}
