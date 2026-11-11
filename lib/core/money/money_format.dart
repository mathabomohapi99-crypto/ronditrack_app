// NEW: en-ZA formatter using integer arithmetic only; no-break spaces (U+00A0) so an amount never wraps
import 'package:ronditrack/core/money/cents.dart';

String formatRand(Cents amount) {
  final v = amount.value;
  final abs = v < 0 ? -v : v;
  final rands = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${v < 0 ? '-' : ''}R\u00A0${_group(rands)},$cents';
}

String _group(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('\u00A0');
    b.write(s[i]);
  }
  return b.toString();
}
