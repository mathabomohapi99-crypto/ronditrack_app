import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/config.dart';
import 'package:ronditrack/app/config_provider.dart';
import 'package:ronditrack/app/retry.dart';
import 'package:ronditrack/app/router.dart';
import 'package:ronditrack/core/session/session.dart';
import 'package:ronditrack/core/theme/app_theme.dart';
import 'package:ronditrack/features/activity/application/activity_providers.dart';
import 'package:ronditrack/features/activity/data/fake_activity_repository.dart';
import 'package:ronditrack/features/home/application/home_providers.dart';
import 'package:ronditrack/features/home/data/fake_home_repository.dart';
import 'package:ronditrack/features/join/application/join_providers.dart';
import 'package:ronditrack/features/join/data/fake_invite_repository.dart';
import 'package:ronditrack/features/payout/application/payout_providers.dart';
import 'package:ronditrack/features/payout/data/fake_payout_repository.dart';
import 'package:ronditrack/features/stokvel/application/stokvel_providers.dart';
import 'package:ronditrack/features/stokvel/data/fake_stokvel_repository.dart';

/// The whole app through the real router, on the real fakes with no delay.
class AppHarness {
  const new(this.tester, this.container);

  final WidgetTester tester;
  final ProviderContainer container;

  Future<void> go(String location) async {
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  /// Android's back gesture.
  Future<void> back() async {
    container.read(routerProvider).pop();
    await tester.pumpAndSettle();
  }

  /// Changes the window while the app is running, like turning a tablet.
  Future<void> resize(Size size) async {
    tester.view.physicalSize = size;
    await tester.pumpAndSettle();
  }

  Future<void> signInAs(String personaId) async {
    container.read(authProvider.notifier).signInAs(personaId);
    await tester.pumpAndSettle();
  }

  Future<void> tapTab(String label) async {
    final bar = find.byType(NavigationBar).evaluate().isNotEmpty
        ? find.byType(NavigationBar)
        : find.byType(NavigationRail);
    await tester.tap(find.descendant(of: bar, matching: find.text(label)));
    await tester.pumpAndSettle();
  }
}

/// Starts the app signed out in a [size] dp window (a compact phone by
/// default). Pass [signedInAs] to sign in first and [textScale] for large text.
Future<AppHarness> pumpApp(
  WidgetTester tester, {
  String? signedInAs,
  Size size = const Size(400, 800),
  double textScale = 1,
  Flavor flavor = Flavor.dev,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: appRetry,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig(
            flavor: flavor,
            apiBaseUrl: 'http://localhost',
            refreshCookieName: 'rt',
          ),
        ),
        homeRepositoryProvider.overrideWith(
          (ref) => FakeHomeRepository(
            personaId: ref.watch(currentPersonaProvider),
            delayScale: 0,
          ),
        ),
        stokvelRepositoryProvider.overrideWith(
          (ref) => FakeStokvelRepository(
            personaId: ref.watch(currentPersonaProvider),
            delayScale: 0,
          ),
        ),
        activityRepositoryProvider.overrideWith(
          (ref) => FakeActivityRepository(
            personaId: ref.watch(currentPersonaProvider),
            delayScale: 0,
          ),
        ),
        payoutRepositoryProvider.overrideWith(
          (ref) => FakePayoutRepository(
            personaId: ref.watch(currentPersonaProvider),
            delayScale: 0,
          ),
        ),
        inviteRepositoryProvider.overrideWith(
          (ref) => FakeInviteRepository(
            personaId: ref.watch(currentPersonaProvider),
            delayScale: 0,
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          routerConfig: ref.watch(routerProvider),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
  final harness = AppHarness(tester, container);
  if (signedInAs != null) await harness.signInAs(signedInAs);
  return harness;
}
