// NEW 10.3: the payout status as the API spells it (Paid / Next / Waiting, see README contract notes) plus unknown for any new one
enum PayoutStatus {
  paid('Paid'),
  next('Next'),
  waiting('Waiting'),
  unknown('');

  const PayoutStatus(this.wire);
  final String wire;

  static PayoutStatus fromWire(String? s) => values.firstWhere(
    (e) => e != unknown && e.wire == s,
    orElse: () => unknown,
  );
}
