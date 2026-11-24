// NEW 11.3: a South African day as half-open UTC bounds.
// SAST is UTC+2 all year, so the phone's own time zone never matters.
const sastOffset = Duration(hours: 2);

class DayBounds {
  const DayBounds(this.startUtc, this.endUtc);

  /// Inclusive: 00:00 SAST on the day.
  final DateTime startUtc;

  /// Exclusive: 00:00 SAST on the next day.
  final DateTime endUtc;
}

/// "1 November" -> 00:00 SAST on 1 Nov up to, not including, 2 Nov.
DayBounds sastDayBounds(int year, int month, int day) {
  final start = DateTime.utc(year, month, day).subtract(sastOffset);
  final end = DateTime.utc(year, month, day + 1).subtract(sastOffset);
  return DayBounds(start, end);
}

/// The South African calendar day (as a UTC-midnight date) of an instant.
DateTime sastDayOf(DateTime instant) {
  final shifted = instant.toUtc().add(sastOffset);
  return DateTime.utc(shifted.year, shifted.month, shifted.day);
}

/// An instant the way the API wants it: UTC, no fractions, like 2026-09-30T22:00:00Z.
String apiInstant(DateTime instant) {
  final u = instant.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  final year = u.year.toString().padLeft(4, '0');
  return '$year-${two(u.month)}-${two(u.day)}T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}
