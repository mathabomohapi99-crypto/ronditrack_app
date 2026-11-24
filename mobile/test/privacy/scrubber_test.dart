import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/privacy/scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('nothing personal survives, the correlation id does', () {
    const amount = 'R 1\u00A0250,50';
    final event = SentryEvent(
      message: SentryMessage(
        'Thandi Nkosi paid $amount with Thandi_proof_Nov.jpg',
      ),
      exceptions: [
        SentryException(
          type: 'ServerFailure',
          value: 'thandi@example.com Bearer abc.def.ghi amountInCents: 125050',
        ),
      ],
      breadcrumbs: [
        Breadcrumb(
          message: 'GET /contributions?q=Nkosi',
          data: {
            'url': 'https://api.example/x?email=thandi@example.com',
            'amount': amount,
          },
        ),
      ],
      tags: {correlationTag: 'corr-123', 'who': 'Thandi Nkosi'},
      user: SentryUser(
        id: '42',
        email: 'thandi@example.com',
        username: 'Thandi Nkosi',
      ),
      request: SentryRequest(
        url: 'https://api.example/x?token=abc',
        cookies: 'refresh_token=abc',
        headers: {'Authorization': 'Bearer eyJhbGciOi.eyJzdWIi.sig'},
        data: {'name': 'Thandi Nkosi'},
      ),
    );
    final json = jsonEncode(
      scrubEvent(event, names: {'Thandi Nkosi'}).toJson(),
    );
    for (final leak in [
      'Thandi',
      'Nkosi',
      'thandi@example.com',
      '1 250',
      '1\u00A0250',
      '125050',
      'Thandi_proof',
      'abc.def.ghi',
      'eyJhbGci',
      'refresh_token=abc',
      'token=abc',
    ]) {
      expect(json.contains(leak), isFalse, reason: 'leaked: $leak');
    }
    expect(json.contains('corr-123'), isTrue);
  });
}
