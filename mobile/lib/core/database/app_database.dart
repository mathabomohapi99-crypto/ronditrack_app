// NEW 11.3: the one Drift database. Each feature owns its tables in its own data/ folder
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:ronditrack/features/payments/data/outbox_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [OutboxPayments])
class AppDatabase extends _$AppDatabase {
  new(super.e);

  @override
  int get schemaVersion => 1;
}

AppDatabase openAppDatabase() => AppDatabase(driftDatabase(name: 'ronditrack'));
