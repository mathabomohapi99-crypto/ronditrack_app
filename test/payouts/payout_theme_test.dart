// NEW 10.3: theme layer: every payout status has a tone that reads at 4.5:1 in light AND dark; reused pairs are really reused
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/core/theme/status_colors.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';

double _contrast(Tone t) {
  final a = t.foreground.computeLuminance();
  final b = t.background.computeLuminance();
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {'light': StatusColors.light, 'dark': StatusColors.dark};

  for (final entry in themes.entries) {
    test('${entry.key}: every payout status is readable (>= 4.5:1)', () {
      for (final s in PayoutStatus.values) {
        expect(
          _contrast(entry.value.forPayout(s)),
          greaterThanOrEqualTo(4.5),
          reason: '$s in ${entry.key}',
        );
      }
    });

    test(
      '${entry.key}: Paid and Waiting reuse measured pairs, Next has its own',
      () {
        final t = entry.value;
        expect(t.forPayout(PayoutStatus.paid), same(t.confirmed));
        expect(t.forPayout(PayoutStatus.waiting), same(t.pending));
        expect(t.forPayout(PayoutStatus.next), same(t.payoutNext));
        expect(identical(t.payoutNext, t.pending), isFalse);
      },
    );
  }

  test('dark is not the light pair flipped', () {
    expect(
      StatusColors.dark.payoutNext.foreground,
      isNot(StatusColors.light.payoutNext.background),
    );
  });
}
