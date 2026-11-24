// NEW 11.3: what the pay form calls. One tap: store the payment (key made here, once), then try to send it
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/features/payments/application/outbox_providers.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

part 'pay_action.g.dart';

enum PayKind { paid, queued, waiting, refused, expired }

class PayOutcome {
  const new(this.kind, {this.message, this.waitFor});

  final PayKind kind;
  final String? message;
  final Duration? waitFor;
}

class PayAction {
  const new(this._outbox);

  final OutboxService _outbox;

  Future<PayOutcome> pay({
    required String stokvelId,
    required String cycleId,
    required int cents,
  }) async {
    final payment = await _outbox.enqueue(
      stokvelId: stokvelId,
      cycleId: cycleId,
      amountCents: cents,
    );
    final results = await _outbox.flush();
    final mine = results
        .where((r) => r.payment.idempotencyKey == payment.idempotencyKey)
        .firstOrNull;
    return switch (mine?.kind) {
      FlushKind.paid => const PayOutcome(PayKind.paid),
      FlushKind.refused => PayOutcome(PayKind.refused, message: mine?.message),
      FlushKind.expired => const PayOutcome(PayKind.expired),
      FlushKind.waiting => PayOutcome(PayKind.waiting, waitFor: mine?.waitFor),
      FlushKind.pending || null => const PayOutcome(PayKind.queued),
    };
  }
}

@Riverpod(keepAlive: true)
PayAction payAction(Ref ref) => PayAction(ref.watch(outboxServiceProvider));
