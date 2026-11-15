// NEW 10.3: provider layer: empty is empty, loading/data/failure map once, two cycles keep separate state
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/core/view_state.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';
import 'package:ronditrack/features/payouts/domain/payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';
import 'package:ronditrack/features/payouts/presentation/payout_providers.dart';

PayoutEntry _entry(String id) => PayoutEntry(
  id: id,
  memberName: 'Member $id',
  position: 1,
  amount: const Cents(100),
  payoutDate: DateTime(2026, 12),
  status: PayoutStatus.waiting,
);

class _CountingRepo implements PayoutRepository {
  int calls = 0;
  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) {
    calls++;
    return Future.value([_entry('$stokvelId/$cycleId')]);
  }
}

class _FailingRepo implements PayoutRepository {
  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) => Future.error(Exception('boom'));
}

void main() {
  bool noOrder(List<PayoutEntry> l) => l.isEmpty;

  test('a cycle with no payout order is empty, not data', () {
    expect(
      toViewState<List<PayoutEntry>>(const AsyncData([]), isEmpty: noOrder),
      isA<ViewEmpty<List<PayoutEntry>>>(),
    );
    expect(
      toViewState<List<PayoutEntry>>(
        AsyncData([_entry('a')]),
        isEmpty: noOrder,
      ),
      isA<ViewData<List<PayoutEntry>>>(),
    );
  });

  test('loading, data and failure each map to one state', () {
    expect(
      toViewState<List<PayoutEntry>>(const AsyncLoading()),
      isA<ViewLoading<List<PayoutEntry>>>(),
    );
    expect(
      toViewState<List<PayoutEntry>>(AsyncData([_entry('a')])),
      isA<ViewData<List<PayoutEntry>>>(),
    );
    expect(
      toViewState<List<PayoutEntry>>(
        AsyncError(Exception('x'), StackTrace.empty),
      ),
      isA<ViewFailure<List<PayoutEntry>>>(),
    );
  });

  test('two cycles keep separate state; one cycle is fetched once', () async {
    final repo = _CountingRepo();
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [payoutRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.listen(payoutOrderProvider('s1', 'c1'), (_, _) {});
    c.listen(payoutOrderProvider('s1', 'c2'), (_, _) {});
    final a = await c.read(payoutOrderProvider('s1', 'c1').future);
    final b = await c.read(payoutOrderProvider('s1', 'c2').future);
    expect(a.single.id, 's1/c1');
    expect(b.single.id, 's1/c2');
    c.listen(payoutOrderProvider('s1', 'c1'), (_, _) {});
    await c.read(payoutOrderProvider('s1', 'c1').future);
    expect(repo.calls, 2);
  });

  test('a failing repository ends as a failure state', () async {
    final c = ProviderContainer(
      retry: (_, _) => null,
      overrides: [payoutRepositoryProvider.overrideWithValue(_FailingRepo())],
    );
    addTearDown(c.dispose);
    c.listen(payoutOrderProvider('s1', 'c1'), (_, _) {});
    await expectLater(
      c.read(payoutOrderProvider('s1', 'c1').future),
      throwsA(isA<Exception>()),
    );
    expect(
      toViewState(c.read(payoutOrderProvider('s1', 'c1'))),
      isA<ViewFailure<List<PayoutEntry>>>(),
    );
  });
}
