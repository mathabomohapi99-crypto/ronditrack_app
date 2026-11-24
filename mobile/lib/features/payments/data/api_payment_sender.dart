// UPDATED 11.3: sends one outbox payment with its stored Idempotency-Key, in the body the API expects
import 'package:dio/dio.dart';
import 'package:ronditrack/core/database/app_database.dart';
import 'package:ronditrack/features/payments/data/outbox_service.dart';

class ApiPaymentSender implements PaymentSender {
  const new(this._dio, this._userId);

  final Dio _dio;
  final String? Function() _userId;

  @override
  Future<SendOutcome> send(OutboxPayment p) async {
    final userId = _userId();
    // Not signed in right now: keep the payment and its key
    if (userId == null) return const SendOutcome(SendKind.noAnswer);
    try {
      await _dio.post<Object?>(
        '/api/v1/stokvels/${p.stokvelId}/contributions',
        data: {
          'userId': userId,
          'contributionCycleId': p.cycleId,
          'amountInCents': p.amountCents,
        },
        options: Options(headers: {'Idempotency-Key': p.idempotencyKey}),
      );
      return const SendOutcome(SendKind.sent);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // No answer, a failed sign-in or a server error: keep it and its key
      if (code == null || code == 401 || code >= 500) {
        return const SendOutcome(SendKind.noAnswer);
      }
      // 429 never consumes the key: wait, then retry with the same key
      if (code == 429) {
        final secs = int.tryParse(
          e.response?.headers.value('retry-after') ?? '',
        );
        return SendOutcome(
          SendKind.rateLimited,
          retryAfter: Duration(seconds: secs ?? 60),
        );
      }
      // 409 already paid / not a member, 404, 403, 422, 400: removed, with the API's words when it has them
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      return SendOutcome(
        SendKind.refused,
        message: detail is String ? detail : null,
      );
    }
  }
}
