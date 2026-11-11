// NEW: parses typed rands to Cents with integer maths. FULL-STOP DECISION: a single "." is accepted as a
// decimal separator (phone keyboards without a comma) but only with 1-2 digits after it, so "1.500" and
// "1,500.50" are refused as ambiguous.
import 'package:ronditrack/core/money/cents.dart';

sealed class MoneyParse {
  const new();
}

final class MoneyOk extends MoneyParse {
  const new(this.cents);
  final Cents cents;
}

final class MoneyErr extends MoneyParse {
  const new(this.reason);
  final String reason;
}

final _pattern = RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$');

MoneyParse parseRands(String input) {
  var s = input.trim();
  if (s.isEmpty) return const MoneyErr('Enter an amount');
  if (s.startsWith('R') || s.startsWith('r')) s = s.substring(1);
  s = s.replaceAll(' ', '').replaceAll('\u00A0', '');
  final m = _pattern.firstMatch(s);
  if (m == null) return const MoneyErr('Use digits only, like 150 or 150,50');
  final rands = int.tryParse(m.group(1)!);
  if (rands == null) return const MoneyErr('Amount is too large');
  final frac = int.parse((m.group(2) ?? '').padRight(2, '0'));
  return MoneyOk(Cents(rands * 100 + frac));
}
