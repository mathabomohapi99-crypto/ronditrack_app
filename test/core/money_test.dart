// NEW: money tests; no-break space written as \u00A0 on purpose
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/core/money/money_format.dart';
import 'package:ronditrack/core/money/money_parse.dart';

int? cents(String s) => switch (parseRands(s)) {
  MoneyOk(:final cents) => cents.value,
  MoneyErr() => null,
};

void main() {
  group('format', () {
    test('en-ZA examples', () {
      expect(formatRand(const Cents(10)), 'R\u00A00,10');
      expect(formatRand(const Cents(15050)), 'R\u00A0150,50');
      expect(formatRand(const Cents(150000)), 'R\u00A01\u00A0500,00');
      expect(
        formatRand(const Cents(100000000)),
        'R\u00A01\u00A0000\u00A0000,00',
      );
      expect(formatRand(const Cents(-15050)), '-R\u00A0150,50');
    });
  });
  group('parse accepts', () {
    test('plain and prefixed', () {
      expect(cents('150'), 15000);
      expect(cents('150,50'), 15050);
      expect(cents('R150'), 15000);
      expect(cents('R 1 500'), 150000);
      expect(cents('1 500,50'), 150050);
      expect(cents('1\u00A0500,50'), 150050);
      expect(
        cents('150.50'),
        15050,
      ); // full-stop decision: decimal when 1-2 digits follow
    });
  });
  group('parse refuses', () {
    test('bad input', () {
      expect(cents('1,500.50'), isNull);
      expect(cents('150,505'), isNull);
      expect(cents('150.'), isNull);
      expect(cents(''), isNull);
      expect(cents('abc'), isNull);
    });
  });
}
