// NEW 10.3: screen layer: every state, Treasurer action by membership, 360 dp at 200%, dark tokens, order exactly as sent
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/core/theme/app_theme.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/features/payouts/data/fake_payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';
import 'package:ronditrack/features/payouts/domain/payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';
import 'package:ronditrack/features/payouts/presentation/payouts_page.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

PayoutEntry _e(String name, int position, PayoutStatus s) => PayoutEntry(
  id: 'p$position',
  memberName: name,
  position: position,
  amount: const Cents(150000),
  payoutDate: DateTime(2026, 11, position),
  status: s,
);

class _Fixed implements PayoutRepository {
  _Fixed(this.entries);
  final List<PayoutEntry> entries;
  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) => Future.value(entries);
}

class _Never implements PayoutRepository {
  final done = Completer<List<PayoutEntry>>();
  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) => done.future;
}

class _Boom implements PayoutRepository {
  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) => Future.error(Exception('boom'));
}

// A stokvel whose cycle is Closed, so the 10.1 actions match allows "Record payout" for a Treasurer only
class _ClosedCycle implements StokvelRepository {
  _ClosedCycle(this.role);
  final StokvelRole role;
  @override
  Future<StokvelDetail> load(String stokvelId) => Future.value(
    StokvelDetail(
      stokvelId: stokvelId,
      name: 'Ubuntu Savers',
      role: role,
      cycle: CycleInfo(
        id: ubuntuCycle3,
        number: 3,
        status: CycleStatus.closed,
        dueDate: DateTime(2026, 11, 30),
      ),
    ),
  );
}

// Uses the app's OWN theme: a chip that reads the theme extension crashes on a bare MaterialApp
Future<void> _pump(
  WidgetTester tester, {
  required PayoutRepository payouts,
  StokvelRepository? stokvels,
  Size size = const Size(400, 800),
  double textScale = 1,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        payoutRepositoryProvider.overrideWithValue(payouts),
        stokvelRepositoryProvider.overrideWithValue(
          stokvels ??
              FakeStokvelRepository(
                persona: Persona.thandi,
                delay: Duration.zero,
              ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const PayoutsPage(stokvelId: ubuntuId, cycleId: ubuntuCycle3),
      ),
    ),
  );
}

void main() {
  final three = [
    _e('Thandi Nkosi', 1, PayoutStatus.paid),
    _e('Sipho Dlamini', 2, PayoutStatus.next),
    _e('Lerato Mokoena', 3, PayoutStatus.waiting),
  ];

  testWidgets('loading shows the spinner', (tester) async {
    await _pump(tester, payouts: _Never());
    await tester.pump();
    expect(find.byKey(const Key('loading')), findsOneWidget);
  });

  testWidgets('empty says so and shows no rows', (tester) async {
    await _pump(tester, payouts: _Fixed(<PayoutEntry>[]));
    await tester.pumpAndSettle();
    expect(
      find.text('No payout order has been set for this cycle yet.'),
      findsOneWidget,
    );
    expect(find.textContaining('Position'), findsNothing);
  });

  testWidgets('data: members, rands and status in words', (tester) async {
    await _pump(tester, payouts: _Fixed(three));
    await tester.pumpAndSettle();
    expect(find.text('Thandi Nkosi'), findsOneWidget);
    expect(find.text('R\u00A01\u00A0500,00'), findsNWidgets(3));
    expect(find.text('Paid out'), findsOneWidget);
    expect(find.text('Next to be paid'), findsOneWidget);
    expect(find.text('Waiting for turn'), findsOneWidget);
  });

  testWidgets('failure says so and has a retry', (tester) async {
    await _pump(tester, payouts: _Boom());
    await tester.pumpAndSettle();
    expect(find.text('Could not load the payouts.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('the order is shown exactly as sent (the app does not sort)', (
    tester,
  ) async {
    await _pump(
      tester,
      payouts: _Fixed([
        _e('Third', 3, PayoutStatus.waiting),
        _e('First', 1, PayoutStatus.paid),
        _e('Second', 2, PayoutStatus.next),
      ]),
    );
    await tester.pumpAndSettle();
    double y(String n) => tester.getTopLeft(find.text(n)).dy;
    expect(y('Third') < y('First'), isTrue);
    expect(y('First') < y('Second'), isTrue);
  });

  testWidgets(
    'Treasurer sees Record payout where the actions match allows it',
    (tester) async {
      await _pump(
        tester,
        payouts: _Fixed(three),
        stokvels: _ClosedCycle(StokvelRole.treasurer),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your role here: Treasurer'), findsOneWidget);
      expect(find.byKey(const Key('recordPayoutButton')), findsOneWidget);
    },
  );

  testWidgets('a Member never sees Record payout', (tester) async {
    await _pump(
      tester,
      payouts: _Fixed(three),
      stokvels: _ClosedCycle(StokvelRole.member),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your role here: Member'), findsOneWidget);
    expect(find.byKey(const Key('recordPayoutButton')), findsNothing);
  });

  testWidgets('360 dp at 200% text: no overflow, last row reachable', (
    tester,
  ) async {
    await _pump(
      tester,
      payouts: _Fixed(three),
      size: const Size(360, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Waiting for turn'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('payoutList')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  for (final b in Brightness.values) {
    testWidgets('${b.name} mode reads the ${b.name} tokens', (tester) async {
      await _pump(tester, payouts: _Fixed(three), brightness: b);
      await tester.pumpAndSettle();
      final tokens = b == Brightness.dark
          ? StatusColors.dark
          : StatusColors.light;
      final chip = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Next to be paid'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (chip.decoration as BoxDecoration).color,
        tokens.payoutNext.background,
      );
    });
  }
}
