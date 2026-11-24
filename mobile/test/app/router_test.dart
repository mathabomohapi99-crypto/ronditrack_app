import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  group('twist: a stokvel you are not in', () {
    testWidgets('a stokvel link reads as not found, never access', (
      tester,
    ) async {
      // Nomsa is only in Umoja Family Fund.
      final app = await pumpApp(tester, signedInAs: 'nomsa');
      await app.go('/stokvels/ubuntu-savings-circle');
      expect(find.text('Stokvel not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    });

    testWidgets('a stokvel that does not exist reads exactly the same', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'nomsa');
      await app.go('/stokvels/no-such-stokvel');
      expect(find.text('Stokvel not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    });

    testWidgets('a cycle of a stokvel you are not in reads as not found', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'nomsa');
      await app.go('/stokvels/ubuntu-savings-circle/cycles/cycle-ubuntu-3');
      expect(find.textContaining('not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    });

    testWidgets('a cycle id from a different stokvel reads as not found', (
      tester,
    ) async {
      // Sipho is in both stokvels, but this cycle belongs to Ubuntu.
      final app = await pumpApp(tester, signedInAs: 'sipho');
      await app.go('/stokvels/umoja-family-fund/cycles/cycle-ubuntu-3');
      expect(find.text('Cycle not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    });

    testWidgets('the same cycle under its own stokvel opens', (tester) async {
      final app = await pumpApp(tester, signedInAs: 'sipho');
      await app.go('/stokvels/umoja-family-fund/cycles/cycle-umoja-5');
      expect(find.text('Cycle 5'), findsOneWidget);
    });
  });

  group('twist: roles per stokvel, by address', () {
    testWidgets('Sipho is Treasurer in one stokvel and Member in the other', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'sipho');

      await app.go('/stokvels/umoja-family-fund');
      expect(find.text('Your role: Treasurer'), findsOneWidget);
      expect(find.text('Confirm contributions'), findsOneWidget);
      expect(find.text('Close cycle'), findsOneWidget);

      await app.go('/stokvels/ubuntu-savings-circle');
      expect(find.text('Your role: Member'), findsOneWidget);
      expect(find.text('Confirm contributions'), findsNothing);
      expect(find.text('Close cycle'), findsNothing);
      expect(find.text('Pay'), findsOneWidget);
    });
  });

  group('twist: a link that survives sign-in', () {
    testWidgets('/join/:code signed out, then signed in, lands on the invite', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await app.go('/join/ubuntu2026');

      expect(find.text('Sign in to open the link you followed.'), findsOne);
      expect(find.text('Invitation'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('email-field')),
        'nomsa@example.com',
      );
      await tester.tap(find.byKey(const Key('sign-in-button')));
      await tester.pumpAndSettle();

      expect(find.text('Invitation'), findsOneWidget);
      expect(find.text('Ubuntu Savings Circle'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('plain sign-in lands on Home', (tester) async {
      final app = await pumpApp(tester);
      await app.signInAs('sipho');
      expect(find.text('RondiTrack'), findsWidgets);
      expect(find.text('Invitation'), findsNothing);
    });
  });

  group('the gate', () {
    testWidgets('signing out lands on sign-in and back cannot return', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'sipho');
      await app.tapTab('Profile');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign-in-button')), findsOneWidget);

      // A signed-out person cannot reach a signed-in address.
      await app.go('/stokvels/umoja-family-fund');
      expect(find.byKey(const Key('sign-in-button')), findsOneWidget);
      expect(find.text('Confirm contributions'), findsNothing);
    });
  });

  group('tabs keep their place', () {
    testWidgets('a cycle opened on Stokvels is still open after a round trip', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'sipho');
      await app.go('/stokvels/umoja-family-fund/cycles/cycle-umoja-5');
      expect(find.text('Cycle 5'), findsOneWidget);

      await app.tapTab('Activity');
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Activity'),
        ),
        findsOneWidget,
      );
      expect(find.text('Cycle 5'), findsNothing);

      await app.tapTab('Stokvels');
      expect(find.text('Cycle 5'), findsOneWidget);
    });

    testWidgets('tapping the tab you are on returns to its first screen', (
      tester,
    ) async {
      final app = await pumpApp(tester, signedInAs: 'sipho');
      await app.go('/stokvels/umoja-family-fund/cycles/cycle-umoja-5');
      await app.tapTab('Stokvels');
      expect(find.text('Cycle 5'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Stokvels'),
        ),
        findsOneWidget,
      );
    });
  });
}
