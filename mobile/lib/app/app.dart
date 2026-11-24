import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ronditrack/app/config.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/settings/locale_choice.dart';
import 'package:ronditrack/l10n/app_localizations.dart';
import 'package:ronditrack/core/theme/app_theme.dart';

class RondiTrackApp extends ConsumerWidget {
  const new({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: config.flavor == Flavor.prod
          ? 'RondiTrack'
          : 'RondiTrack ${config.flavor.name}',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(localeChoiceProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
