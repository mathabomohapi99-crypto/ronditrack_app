import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/push/push_payload.dart';

void main() {
  test('the lock-screen words carry no name, amount or decision', () {
    final words = '$pushTitle $pushBody'.toLowerCase();
    expect(RegExp(r'\d').hasMatch(words), isFalse);
    for (final banned in [
      'confirm',
      'paid',
      'payment',
      'closed',
      'payout',
      'r ',
      'rand',
    ]) {
      expect(words.contains(banned), isFalse, reason: 'says: $banned');
    }
  });
}
