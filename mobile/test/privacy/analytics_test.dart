import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/privacy/analytics.dart';

void main() {
  test('events carry only ids: no name, email or amount can fit', () {
    final a = RecordingAnalytics()
      ..log('payment_started', stokvelId: 's-1', memberId: 'm-1')
      ..log('home_opened');
    final idShape = RegExp(r'^[\w\-]+$');
    for (final e in a.events) {
      expect(
        e.fields.keys.toSet().difference({'stokvelId', 'memberId'}),
        isEmpty,
      );
      for (final v in e.fields.values) {
        expect(idShape.hasMatch(v), isTrue, reason: 'not an id: $v');
      }
    }
  });
}
