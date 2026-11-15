// UPDATED 10.3: whole-app harness. Same retry rule as the app, a flavour per test, repositories that follow the current person
// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/app/retry.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/config/app_config.dart';
import 'package:ronditrack/core/config/app_config_provider.dart';
import 'package:ronditrack/features/auth/auth_provider.dart';
import 'package:ronditrack/features/payouts/data/fake_payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_repository.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

const prodConfig = AppConfig(
  flavor: 'prod',
  apiBaseUrl: 'https://api.example.invalid',
);
const devConfig = AppConfig(flavor: 'dev', apiBaseUrl: 'http://10.0.2.2:5134');

class FakeAuth extends Auth {
  FakeAuth(this.initial);
  final Persona? initial;
  @override
  Persona? build() => initial;
}

// Starts the "current demo person" as a given persona, so repositories follow persona switches
class FakePersona extends CurrentPersona {
  FakePersona(this.initial);
  final Persona initial;
  @override
  Persona build() => initial;
}

Future<GoRouter> pumpApp(
  WidgetTester tester, {
  Persona? user,
  String location = '/',
  Persona? repoPersona,
  StokvelRepository? stokvelRepo,
  PayoutRepository? payoutRepo,
  AppConfig config = prodConfig,
  Brightness? brightness,
  Size size = const Size(400, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
  }
  if (brightness != null) {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
  }
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  final start = repoPersona ?? user ?? Persona.thandi;
  await tester.pumpWidget(
    ProviderScope(
      retry: appRetry,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        authProvider.overrideWith(() => FakeAuth(user)),
        currentPersonaProvider.overrideWith(() => FakePersona(start)),
        homeRepositoryProvider.overrideWith(
          (ref) => FakeHomeRepository(
            persona: ref.watch(currentPersonaProvider),
            delay: Duration.zero,
          ),
        ),
        stokvelRepositoryProvider.overrideWith(
          (ref) =>
              stokvelRepo ??
              FakeStokvelRepository(
                persona: ref.watch(currentPersonaProvider),
                delay: Duration.zero,
              ),
        ),
        payoutRepositoryProvider.overrideWith(
          (ref) =>
              payoutRepo ??
              FakePayoutRepository(
                persona: ref.watch(currentPersonaProvider),
                delay: Duration.zero,
              ),
        ),
        initialLocationProvider.overrideWithValue(location),
      ],
      child: const RondiApp(title: 'test'),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(RondiApp)))
      .read(routerProvider);
}
