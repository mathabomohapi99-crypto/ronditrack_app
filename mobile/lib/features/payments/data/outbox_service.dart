// NEW 11.3: pay with no signal. The key is made when the person taps Pay and is stored with the payment,
// never made in the code that sends. Every attempt (retry, restart) sends that same key.
import 'package:drift/drift.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

/// How long the outbox keeps a payment. It MUST be shorter than the API's M.
const outboxMaxAge = Duration(hours: 24);

/// M: the API keeps an idempotency key this long (Housekeeping:IdempotencyRetentionHours, default 168 h).
const apiIdempotencyRetention = Duration(hours: 168);

enum SendKind { sent, refused, rateLimited, noAnswer }

class SendOutcome {
  const new(this.kind, {this.message, this.retryAfter});

  final SendKind kind;
  final String? message;
  final Duration? retryAfter;
}

abstract interface class PaymentSender {
  Future<SendOutcome> send(OutboxPayment payment);
}

enum FlushKind { paid, refused, expired, waiting, pending }

class FlushResult {
  const new(this.kind, this.payment, {this.message, this.waitFor});

  final FlushKind kind;
  final OutboxPayment payment;
  final String? message;
  final Duration? waitFor;
}

class OutboxService {
  new(
    this._db,
    this._sender, {
    Duration maxAge = outboxMaxAge,
    DateTime Function()? now,
    Uuid uuid = const Uuid(),
  }) : _maxAge = maxAge,
       _now = now ?? DateTime.now,
       _uuid = uuid;

  final AppDatabase _db;
  final PaymentSender _sender;
  final Duration _maxAge;
  final DateTime Function() _now;
  final Uuid _uuid;

  /// One tap, one payment: a second tap for the same cycle gets the same row (and the same key).
  Future<OutboxPayment> enqueue({
    required String stokvelId,
    required String cycleId,
    required int amountCents,
  }) async {
    final existing =
        await (_db.select(_db.outboxPayments)..where(
              (t) => t.stokvelId.equals(stokvelId) & t.cycleId.equals(cycleId),
            ))
            .getSingleOrNull();
    if (existing != null) return existing;
    final key = _uuid.v4();
    await _db
        .into(_db.outboxPayments)
        .insert(
          OutboxPaymentsCompanion.insert(
            idempotencyKey: key,
            stokvelId: stokvelId,
            cycleId: cycleId,
            amountCents: amountCents,
            createdAt: _now(),
          ),
        );
    return (_db.select(
      _db.outboxPayments,
    )..where((t) => t.idempotencyKey.equals(key))).getSingle();
  }

  Future<List<OutboxPayment>> pending() => (_db.select(
    _db.outboxPayments,
  )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  Stream<List<OutboxPayment>> watchPending() => (_db.select(
    _db.outboxPayments,
  )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  Future<void> _remove(String key) => (_db.delete(
    _db.outboxPayments,
  )..where((t) => t.idempotencyKey.equals(key))).go();

  Future<void> _bump(String key, int attempts, DateTime? notBefore) =>
      (_db.update(
        _db.outboxPayments,
      )..where((t) => t.idempotencyKey.equals(key))).write(
        OutboxPaymentsCompanion(
          attempts: Value(attempts),
          retryNotBefore: Value(notBefore),
        ),
      );

  /// Sends what is waiting, oldest first, one at a time. Each outcome has one result.
  Future<List<FlushResult>> flush() async {
    final results = <FlushResult>[];
    for (final p in await pending()) {
      final now = _now();
      if (now.difference(p.createdAt) > _maxAge) {
        // Too old: never sent again; the person is told to check and pay again
        await _remove(p.idempotencyKey);
        results.add(FlushResult(FlushKind.expired, p));
        continue;
      }
      final wait = p.retryNotBefore;
      if (wait != null && wait.isAfter(now)) {
        results.add(
          FlushResult(FlushKind.waiting, p, waitFor: wait.difference(now)),
        );
        continue;
      }
      final outcome = await _sender.send(p);
      switch (outcome.kind) {
        case SendKind.sent:
          await _remove(p.idempotencyKey);
          results.add(FlushResult(FlushKind.paid, p));
        case SendKind.refused:
          await _remove(p.idempotencyKey);
          results.add(
            FlushResult(FlushKind.refused, p, message: outcome.message),
          );
        case SendKind.rateLimited:
          final after = outcome.retryAfter ?? const Duration(seconds: 60);
          await _bump(p.idempotencyKey, p.attempts + 1, now.add(after));
          results.add(FlushResult(FlushKind.waiting, p, waitFor: after));
          return results;
        case SendKind.noAnswer:
          await _bump(p.idempotencyKey, p.attempts + 1, p.retryNotBefore);
          results.add(FlushResult(FlushKind.pending, p));
          return results;
      }
    }
    return results;
  }

  /// Sign-out: the whole outbox goes (the screen asks first when it is not empty).
  Future<void> clearAll() => _db.delete(_db.outboxPayments).go();
}
