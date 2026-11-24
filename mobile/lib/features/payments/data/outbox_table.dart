// NEW 11.3: the outbox table. One row per tapped payment; the idempotency key is made ONCE, at the tap, and stored here
import 'package:drift/drift.dart';

class OutboxPayments extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get stokvelId => text()();
  TextColumn get cycleId => text()();
  IntColumn get amountCents => integer()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get retryNotBefore => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {idempotencyKey};
}
