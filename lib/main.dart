// UPDATED 10.3: config goes into a provider, and the app uses the one retry rule
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/app/retry.dart';
import 'package:ronditrack/core/config/app_config.dart';
import 'package:ronditrack/core/config/app_config_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.load();
  runApp(
    ProviderScope(
      retry: appRetry,
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: RondiApp(title: 'RondiTrack (${config.flavor})'),
    ),
  );
}
