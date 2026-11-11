// NEW 10.2: router-level widget tests: the three twists, tab stack, back from cold start, one-frame test
// ignore_for_file: always_use_package_imports
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

import '../support/app_harness.dart';

StokvelDetail _detail(String id, String who) => StokvelDetail(
  stokvelId: id,
  name: 'Stokvel $id',
  role: StokvelRole.member,
  cycle: CycleInfo(
    number: 1,
    status: CycleStatus.open,
    dueDate: DateTime(2026, 12),
  ),
  contributions: [
    ContributionItem(
      id: id,
      memberName: who,
      amount: const Cents(100),
      status: ContributionStatus.pending,
      isMine: false,
    ),
  ],
);

class _SlowRepo implements StokvelRepository {
  _SlowRepo(this.b);
  final Completer<StokvelDetail> b;
  @override
  Future<StokvelDetail> load(String id) =>
      id == 'B' ? b.future : Future.value(_detail('A', 'A-member'));
}

void main() {
  testWidgets(
    'non-member sees "not found" for a stokvel, same as a missing one',
    (tester) async {
      await pumpApp(
        tester,
        user: Persona.sipho,
        location: '/stokvels/$groceryId',
      );
      expect(find.text('Not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
      final r = await pumpApp(
        tester,
        user: Persona.sipho,
        location: '/stokvels/does-not-exist',
      );
      expect(find.text('Not found'), findsOneWidget);
      expect(r, isNotNull);
    },
  );

  testWidgets(
    'a cycle of ANOTHER stokvel is "not found"; Sipho cannot open a cycle of a stokvel he is not in',
    (tester) async {
      await pumpApp(
        tester,
        user: Persona.thandi,
        location: '/stokvels/$ubuntuId/cycles/grocery-cycle-2',
      );
      expect(find.text('Not found'), findsOneWidget);
      await pumpApp(
        tester,
        user: Persona.sipho,
        location: '/stokvels/$groceryId/cycles/grocery-cycle-2',
      );
      expect(find.text('Not found'), findsOneWidget);
      expect(find.textContaining('access'), findsNothing);
    },
  );

  testWidgets('a valid cycle opens', (tester) async {
    await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/$ubuntuId/cycles/ubuntu-cycle-3',
    );
    expect(find.byKey(const Key('cyclePage')), findsOneWidget);
  });

  testWidgets(
    'Thandi: Treasurer actions in Ubuntu, none in Festive (she is a Member there)',
    (tester) async {
      final router = await pumpApp(
        tester,
        user: Persona.thandi,
        location: '/stokvels/$ubuntuId',
      );
      expect(find.text('Close cycle'), findsOneWidget);
      router.go('/stokvels/$groceryId');
      await tester.pumpAndSettle();
      expect(find.text('Close cycle'), findsNothing);
      expect(find.text('Confirm contributions'), findsNothing);
      expect(find.text('Pay'), findsOneWidget);
    },
  );

  testWidgets('/join/:code signed out -> sign in -> lands on the invite', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: null,
      location: '/join/ABC123',
      repoPersona: Persona.thandi,
    );
    expect(find.byKey(const Key('signInPage')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'thandi.nkosi@example.com',
    );
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();
    expect(find.text('Invite code: ABC123'), findsOneWidget);
    expect(find.byKey(const Key('signInPage')), findsNothing);
  });

  testWidgets('sign out lands on sign-in', (tester) async {
    await pumpApp(tester, user: Persona.thandi, location: '/profile');
    await tester.tap(find.byKey(const Key('signOutButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInPage')), findsOneWidget);
  });

  testWidgets('a tab keeps its stack: open cycle, visit Activity, come back', (
    tester,
  ) async {
    await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/$ubuntuId/cycles/ubuntu-cycle-3',
    );
    expect(find.byKey(const Key('cyclePage')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Activity'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('activityPage')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Stokvels'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cyclePage')), findsOneWidget);
  });

  testWidgets(
    'cold start on a cycle: back goes to the stokvel, not out of the app',
    (tester) async {
      final router = await pumpApp(
        tester,
        user: Persona.thandi,
        location: '/stokvels/$ubuntuId/cycles/ubuntu-cycle-3',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Your role here: Treasurer'), findsOneWidget);
    },
  );

  testWidgets('one frame after switching: B loading, never A under B', (
    tester,
  ) async {
    final b = Completer<StokvelDetail>();
    final router = await pumpApp(
      tester,
      user: Persona.thandi,
      location: '/stokvels/A',
      stokvelRepo: _SlowRepo(b),
    );
    expect(find.text('A-member'), findsOneWidget);
    router.go('/stokvels/B');
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('loading')), findsWidgets);
    expect(find.text('A-member'), findsNothing);
    b.complete(_detail('B', 'B-member'));
    await tester.pumpAndSettle();
    expect(find.text('B-member'), findsOneWidget);
  });
}
