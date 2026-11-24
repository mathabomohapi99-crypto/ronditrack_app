import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

import '../support/fake_payment_server.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'a retry after no answer sends the same key: the server stores one',
    () async {
      final server = FakePaymentServer([Reply.lost, Reply.ok]);
      final s = OutboxService(db, server);
      await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 25000);
      await s.flush();
      await s.flush();
      expect(server.keysSeen.length, 2);
      expect(server.keysSeen.first, server.keysSeen.last);
      expect(server.stored.length, 1);
      expect(await s.pending(), isEmpty);
    },
  );

  test(
    'a 429 keeps the key, sends nothing before Retry-After, then the same key',
    () async {
      var clock = DateTime.utc(2026, 11, 24, 10);
      final server = FakePaymentServer([Reply.limited, Reply.ok]);
      final s = OutboxService(db, server, now: () => clock);
      final p = await s.enqueue(
        stokvelId: 's1',
        cycleId: 'c1',
        amountCents: 100,
      );
      await s.flush();
      clock = clock.add(const Duration(seconds: 10));
      await s.flush();
      expect(server.keysSeen.length, 1, reason: 'nothing before Retry-After');
      clock = clock.add(const Duration(seconds: 25));
      await s.flush();
      expect(server.keysSeen, [p.idempotencyKey, p.idempotencyKey]);
      expect(server.stored.length, 1);
    },
  );

  test(
    'killed mid-request: a new database over the same file sends the same key',
    () async {
      final dir = Directory.systemTemp.createTempSync('outbox_kill');
      final file = File('${dir.path}/db.sqlite');
      final server = FakePaymentServer([Reply.lost, Reply.ok]);

      final db1 = AppDatabase(NativeDatabase(file));
      final s1 = OutboxService(db1, server);
      await s1.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 500);
      await s1.flush(); // the server got it, the answer was lost, then the app is killed
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(file));
      final s2 = OutboxService(db2, server);
      await s2.flush();
      expect(server.keysSeen.length, 2);
      expect(server.keysSeen.first, server.keysSeen.last);
      expect(server.stored.length, 1);
      expect(await s2.pending(), isEmpty);
      await db2.close();
      dir.deleteSync(recursive: true);
    },
  );

  test('a 409 leaves the outbox, says why, and is never sent again', () async {
    final server = FakePaymentServer([Reply.alreadyPaid]);
    final s = OutboxService(db, server);
    await s.enqueue(stokvelId: 's1', cycleId: 'c1', amountCents: 100);
    final first = await s.flush();
    expect(first.single.kind, FlushKind.refused);
    expect(first.single.message, 'Already paid for this cycle.');
    await s.flush();
    await s.flush();
    expect(server.keysSeen.length, 1);
    expect(await s.pending(), isEmpty);
  });
}
