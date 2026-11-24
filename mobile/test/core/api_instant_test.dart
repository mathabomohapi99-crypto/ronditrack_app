import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/time/sast_day.dart';

void main() {
  test('1 November in South Africa becomes the API instants', () {
    final b = sastDayBounds(2026, 11, 1);
    expect(apiInstant(b.startUtc), '2026-10-31T22:00:00Z');
    expect(apiInstant(b.endUtc), '2026-11-01T22:00:00Z');
  });
}
