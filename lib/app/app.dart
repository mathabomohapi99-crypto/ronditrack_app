// NEW 10.2: the app widget: router + light/dark theme that follows the phone
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/theme/app_theme.dart';

class RondiApp extends ConsumerWidget {
  const RondiApp({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: title,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    routerConfig: ref.watch(routerProvider),
  );
}
