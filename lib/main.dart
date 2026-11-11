// NEW 10.2: entry point: config check, then the router app (no more home: HomePage)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.load();
  // retry off so a 404-like NotFound shows at once instead of retrying with backoff
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      child: RondiApp(title: 'RondiTrack (${config.flavor})'),
    ),
  );
}
