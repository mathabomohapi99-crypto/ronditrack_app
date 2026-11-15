// NEW 10.3: domain layer: every status maps, a new one is unknown, every status has its own words
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/payouts/domain/payout_labels.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';

void main() {
  test('every status the API sends maps to its own case', () {
    expect(PayoutStatus.fromWire('Paid'), PayoutStatus.paid);
    expect(PayoutStatus.fromWire('Next'), PayoutStatus.next);
    expect(PayoutStatus.fromWire('Waiting'), PayoutStatus.waiting);
  });

  test('a status the app has never seen is unknown, not a crash', () {
    expect(PayoutStatus.fromWire('Skipped'), PayoutStatus.unknown);
    expect(PayoutStatus.fromWire(null), PayoutStatus.unknown);
    expect(PayoutStatus.fromWire(''), PayoutStatus.unknown);
    expect(PayoutStatus.fromWire('paid'), PayoutStatus.unknown); // case counts
  });

  test('every status has different words', () {
    final labels = {for (final s in PayoutStatus.values) payoutStatusLabel(s)};
    expect(labels.length, PayoutStatus.values.length);
    expect(payoutStatusLabel(PayoutStatus.unknown), 'Unknown status');
  });

  test('an entry holds the shape the API sends', () {
    final e = PayoutEntry(
      id: 'p1',
      memberName: 'Thandi Nkosi',
      position: 1,
      amount: const Cents(150000),
      payoutDate: DateTime(2026, 10, 31),
      status: PayoutStatus.paid,
    );
    expect(e.amount.value, 150000);
    expect(e.copyWith(status: PayoutStatus.next).status, PayoutStatus.next);
  });
}
