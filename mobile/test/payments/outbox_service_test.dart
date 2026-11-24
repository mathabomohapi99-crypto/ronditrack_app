import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

class FakeSender implements PaymentSender {
  FakeSender(this.outcomes);

  final List<SendOutcome> outcomes;
  final keys = <String>[];

  @override
  Future<SendOutcome> send(OutboxPayment payment) async {
    keys.add(payment.idempotencyKey);
    return outcomes.removeAt(0);
  }
}

OutboxService makeService(
  AppDatabase db,
  FakeSender sender, {
  DateTime Function()? now,
}) => OutboxService(db, sender, now: now);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('one tap makes one key, and a second tap reuses the payment', () async {
    final s = makeService(db, FakeSender([]));
    final a = await s.enqueue(
      stokvelId: 's1',
      cycleId: 'c1',
      amountCents: 25000,
    );
    final b = await s.enqueue(
      stokvelId: 's1',
      cycleId: 'c1',
      amountCents: 25000,
    );
    expect(b.idempotencyKey, a.idempotencyKey);
    expect((await s.pending()).length, 1);
  });

  test('the same key is sent on every attempt', () async {
    final sender = FakeSender([
      const SendOutcome(SendKind.noAnswer),
      const SendOutcome(SendKind.noAnswer),
      const SendOutcome(SendKind.sent),
    ]);
    final s = makeService(db, sender);
    final p = await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    await s.flush();
    await s.flush();
    await s.flush();
    expect(sender.keys, [p.idempotencyKey, p.idempotencyKey, p.idempotencyKey]);
    expect(await s.pending(), isEmpty);
  });

  test(
    'the key survives a restart (database closed and opened again)',
    () async {
      final dir = Directory.systemTemp.createTempSync('outbox');
      final file = File('${dir.path}/db.sqlite');
      final db1 = AppDatabase(NativeDatabase(file));
      final p = await makeService(
        db1,
        FakeSender([]),
      ).enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 500);
      await db1.close();
      final db2 = AppDatabase(NativeDatabase(file));
      final again = await makeService(db2, FakeSender([])).pending();
      expect(again.single.idempotencyKey, p.idempotencyKey);
      await db2.close();
      dir.deleteSync(recursive: true);
    },
  );

  test('a refusal removes the payment and says why', () async {
    final s = makeService(
      db,
      FakeSender([
        const SendOutcome(SendKind.refused, message: 'Already paid.'),
      ]),
    );
    await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    final r = await s.flush();
    expect(r.single.kind, FlushKind.refused);
    expect(r.single.message, 'Already paid.');
    expect(await s.pending(), isEmpty);
  });

  test('a 429 keeps the payment and its key and waits', () async {
    var clock = DateTime.utc(2026, 11, 24, 10);
    final sender = FakeSender([
      const SendOutcome(
        SendKind.rateLimited,
        retryAfter: Duration(seconds: 30),
      ),
    ]);
    final s = makeService(db, sender, now: () => clock);
    final p = await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    final r = await s.flush();
    expect(r.single.kind, FlushKind.waiting);
    clock = clock.add(const Duration(seconds: 10));
    expect((await s.flush()).single.kind, FlushKind.waiting);
    expect(sender.keys.length, 1);
    expect((await s.pending()).single.idempotencyKey, p.idempotencyKey);
  });

  test('no answer keeps it pending, never paid', () async {
    final s = makeService(
      db,
      FakeSender([const SendOutcome(SendKind.noAnswer)]),
    );
    await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    expect((await s.flush()).single.kind, FlushKind.pending);
    expect((await s.pending()).length, 1);
  });

  test('after the maximum age it is never sent again', () async {
    var clock = DateTime.utc(2026, 11, 24, 10);
    final sender = FakeSender([]);
    final s = makeService(db, sender, now: () => clock);
    await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    clock = clock.add(outboxMaxAge + const Duration(minutes: 1));
    expect((await s.flush()).single.kind, FlushKind.expired);
    expect(sender.keys, isEmpty);
    expect(await s.pending(), isEmpty);
  });

  test('sign-out empties the outbox', () async {
    final s = makeService(db, FakeSender([]));
    await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    await s.clearAll();
    expect(await s.pending(), isEmpty);
  });

  test('the outbox maximum age is shorter than the API key lifetime M', () {
    expect(outboxMaxAge < apiIdempotencyRetention, isTrue);
  });
}
