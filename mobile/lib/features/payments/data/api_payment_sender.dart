// NEW 11.3: sends one outbox payment to the API with its stored Idempotency-Key
import 'package:dio/dio.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

class ApiPaymentSender implements PaymentSender {
  const new(this._dio);

  final Dio _dio;

  @override
  Future<SendOutcome> send(OutboxPayment p) async {
    try {
      await _dio.post<Object?>(
        // ASSUMPTION: path and body. Check StokvelEndpoints.cs (record contribution) and fix both.
        '/api/v1/stokvels/${p.stokvelId}/contributions',
        data: {'cycleId': p.cycleId, 'amountCents': p.amountCents},
        options: Options(headers: {'Idempotency-Key': p.idempotencyKey}),
      );
      return const SendOutcome(SendKind.sent);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // No answer, a failed sign-in or a server error: keep it and its key
      if (code == null || code == 401 || code >= 500) {
        return const SendOutcome(SendKind.noAnswer);
      }
      if (code == 429) {
        final secs = int.tryParse(
          e.response?.headers.value('retry-after') ?? '',
        );
        return SendOutcome(
          SendKind.rateLimited,
          retryAfter: Duration(seconds: secs ?? 60),
        );
      }
      // Already paid, cycle closed, not a member...: removed, with the API's words when it has them
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      return SendOutcome(
        SendKind.refused,
        message: detail is String ? detail : 'The payment was refused.',
      );
    }
  }
}
