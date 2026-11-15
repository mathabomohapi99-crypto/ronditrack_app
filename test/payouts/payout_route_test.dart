// NEW 10.3: route layer: the address sits in the Stokvels tab, back goes to the cycle, a signed-out link survives sign-in
// ignore_for_file: always_use_package_imports
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/features/payouts/data/fake_payout_repository.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

import '../support/app_harness.dart';

const _address = '/stokvels/$ubuntuId/cycles/$ubuntuCycle3/payouts';

void main() {
  testWidgets('the payouts address opens in the Stokvels tab', (tester) async {
    await pumpApp(tester, user: Persona.thandi, location: _address);
    expect(find.byKey(const Key('payoutsPage')), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1); // Home 0, Stokvels 1, Activity 2, Profile 3
  });

  testWidgets('cold start on payouts: back goes to the cycle', (tester) async {
    final router = await pumpApp(
      tester,
      user: Persona.thandi,
      location: _address,
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cyclePage')), findsOneWidget);
  });

  testWidgets('signed out: the link survives sign-in and lands on payouts', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: null,
      location: _address,
      repoPersona: Persona.thandi,
    );
    expect(find.byKey(const Key('signInPage')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'thandi.nkosi@example.com',
    );
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payoutsPage')), findsOneWidget);
    expect(find.byKey(const Key('signInPage')), findsNothing);
  });

  testWidgets('the cycle screen links to its payouts', (tester) async {
    await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/$ubuntuId/cycles/$ubuntuCycle3',
    );
    await tester.tap(find.byKey(const Key('payoutsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payoutsPage')), findsOneWidget);
  });
}
