import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

enum Reply { ok, lost, limited, alreadyPaid }

/// A pretend API: one stored contribution per Idempotency-Key, like the real one.
class FakePaymentServer implements PaymentSender {
  FakePaymentServer(List<Reply> script) : _script = [...script];

  final List<Reply> _script;
  final stored = <String, int>{};
  final keysSeen = <String>[];

  @override
  Future<SendOutcome> send(OutboxPayment payment) async {
    keysSeen.add(payment.idempotencyKey);
    final reply = _script.isEmpty ? Reply.ok : _script.removeAt(0);
    switch (reply) {
      case Reply.ok:
        stored.putIfAbsent(payment.idempotencyKey, () => payment.amountCents);
        return const SendOutcome(SendKind.sent);
      case Reply.lost:
        // The server got it; the answer never came back
        stored.putIfAbsent(payment.idempotencyKey, () => payment.amountCents);
        return const SendOutcome(SendKind.noAnswer);
      case Reply.limited:
        return const SendOutcome(
          SendKind.rateLimited,
          retryAfter: Duration(seconds: 30),
        );
      case Reply.alreadyPaid:
        return const SendOutcome(
          SendKind.refused,
          message: 'Already paid for this cycle.',
        );
    }
  }
}
