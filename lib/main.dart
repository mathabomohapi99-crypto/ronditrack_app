// NEW: entry point: config must load (else the app refuses to start), then Riverpod + Home
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/core/config/app_config.dart';
import 'package:ronditrack/features/stokvels/presentation/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config =
      AppConfig.load(); // throws ConfigError on missing/mismatched config
  runApp(ProviderScope(child: RondiApp(config: config)));
}

class RondiApp extends StatelessWidget {
  const new({required this.config, super.key});
  final AppConfig config;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RondiTrack (${config.flavor})',
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: const HomePage(),
  );
}
