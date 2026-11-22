import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/time/sast_day.dart';

void main() {
  test('1 November is 00:00 SAST up to, not including, 2 November', () {
    final b = sastDayBounds(2026, 11, 1);
    expect(b.startUtc, DateTime.utc(2026, 10, 31, 22));
    expect(b.endUtc, DateTime.utc(2026, 11, 1, 22));
  });

  test('00:30 SAST on 1 November is on 1 November, not 31 October', () {
    final instant = DateTime.utc(2026, 10, 31, 22, 30);
    expect(sastDayOf(instant), DateTime.utc(2026, 11));
    final b = sastDayBounds(2026, 11, 1);
    expect(!instant.isBefore(b.startUtc) && instant.isBefore(b.endUtc), isTrue);
  });

  test('the end bound belongs to the next day', () {
    final b = sastDayBounds(2026, 11, 1);
    expect(sastDayOf(b.endUtc), DateTime.utc(2026, 11, 2));
  });
}
