// UPDATED 11.3: the database, the outbox, and the pending payments as a stream
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/core/network/dev_session.dart';
import 'package:ronditrack/core/network/dio_provider.dart';
import 'package:ronditrack/features/payments/data/api_payment_sender.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

part 'outbox_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
OutboxService outboxService(Ref ref) => OutboxService(
  ref.watch(appDatabaseProvider),
  ApiPaymentSender(
    ref.watch(dioProvider),
    () => ref.read(devSessionProvider).userId,
  ),
);

/// Payments waiting to be sent. Shown beside the server's totals, marked pending, never added in.
@riverpod
Stream<List<OutboxPayment>> pendingPayments(Ref ref) =>
    ref.watch(outboxServiceProvider).watchPending();
