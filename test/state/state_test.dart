// NEW: view-state mapping, family provider isolation/sharing, and the "never the wrong stokvel" frame test
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';
import 'package:ronditrack/features/stokvels/presentation/detail_page.dart';
import 'package:ronditrack/features/stokvels/presentation/home_page.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';

StokvelDetail _d(String id, String who) => StokvelDetail(
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

class _Repo implements StokvelRepository {
  new(this.b);
  final Completer<StokvelDetail> b;
  int calls = 0;
  @override
  Future<StokvelDetail> load(String id) {
    calls++;
    return id == 'B' ? b.future : Future.value(_d('A', 'A-member'));
  }
}

class _Failing implements HomeRepository {
  @override
  Future<List<HomeEntry>> loadHome() => Future.error(Exception('boom'));
}

void main() {
  test('"no stokvels" is empty, not data', () {
    expect(
      toViewState<List<int>>(const AsyncData([]), isEmpty: (l) => l.isEmpty),
      isA<ViewEmpty<List<int>>>(),
    );
    expect(
      toViewState<List<int>>(const AsyncData([1]), isEmpty: (l) => l.isEmpty),
      isA<ViewData<List<int>>>(),
    );
    expect(
      toViewState<List<int>>(const AsyncLoading()),
      isA<ViewLoading<List<int>>>(),
    );
  });

  test(
    'family: two ids separate; two listeners on one id share one fetch',
    () async {
      final repo = _Repo(Completer());
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [stokvelRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      c.listen(stokvelDetailProvider('A'), (_, _) {});
      c.listen(stokvelDetailProvider('A'), (_, _) {});
      await c.read(stokvelDetailProvider('A').future);
      expect(repo.calls, 1);
      c.listen(stokvelDetailProvider('B'), (_, _) {});
      expect(c.read(stokvelDetailProvider('B')).isLoading, isTrue);
      expect(c.read(stokvelDetailProvider('A')).hasValue, isTrue);
    },
  );

  testWidgets('frame test: after switching, B loading and none of A', (
    tester,
  ) async {
    final b = Completer<StokvelDetail>();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [stokvelRepositoryProvider.overrideWithValue(_Repo(b))],
        child: const MaterialApp(
          home: StokvelDetailPage(
            initialId: 'A',
            choices: [
              (id: 'A', name: 'Stokvel A'),
              (id: 'B', name: 'Stokvel B'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A-member'), findsOneWidget);
    await tester.tap(find.byKey(const Key('picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stokvel B').last);
    await tester.pump(); // exactly one frame
    expect(find.byKey(const Key('loading')), findsOneWidget);
    expect(find.text('A-member'), findsNothing);
    b.complete(_d('B', 'B-member'));
    await tester.pumpAndSettle();
    expect(find.text('B-member'), findsOneWidget);
  });

  testWidgets('Home: empty persona', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            FakeHomeRepository(persona: Persona.bongani, delay: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('not in any stokvels'), findsOneWidget);
  });

  testWidgets('Home: data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          homeRepositoryProvider.overrideWithValue(
            FakeHomeRepository(persona: Persona.thandi, delay: Duration.zero),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ubuntu Savers'), findsOneWidget);
    expect(find.textContaining('Treasurer'), findsWidgets);
  });

  testWidgets('Home: failure has retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [homeRepositoryProvider.overrideWithValue(_Failing())],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
  });
}
