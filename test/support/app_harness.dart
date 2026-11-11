// NEW 10.2: pumps the whole router app as a persona at an address; fakes have zero delay
// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ronditrack/app/app.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/features/auth/auth_provider.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

class FakeAuth extends Auth {
  FakeAuth(this.initial);
  final Persona? initial;
  @override
  Persona? build() => initial;
}

Future<GoRouter> pumpApp(
  WidgetTester tester, {
  Persona? user,
  String location = '/',
  Persona? repoPersona,
  StokvelRepository? stokvelRepo,
  Size size = const Size(400, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }
  final p = repoPersona ?? user ?? Persona.thandi;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(() => FakeAuth(user)),
        homeRepositoryProvider.overrideWithValue(
          FakeHomeRepository(persona: p, delay: Duration.zero),
        ),
        stokvelRepositoryProvider.overrideWithValue(
          stokvelRepo ??
              FakeStokvelRepository(persona: p, delay: Duration.zero),
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
