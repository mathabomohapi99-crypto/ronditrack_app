// NEW: API enums with an unknown case; wire strings = the API's exact spellings (VERIFY against Domain/*.cs)
enum CycleStatus {
  open('Open'),
  closed('Closed'),
  paidOut('PaidOut'),
  unknown('');

  new(this.wire);
  final String wire;
  static CycleStatus fromWire(String? s) => values.firstWhere(
    (e) => e != unknown && e.wire == s,
    orElse: () => unknown,
  );
}

enum ContributionStatus {
  pending('Pending'),
  paid('Paid'),
  confirmed('Confirmed'),
  unknown('');

  new(this.wire);
  final String wire;
  static ContributionStatus fromWire(String? s) => values.firstWhere(
    (e) => e != unknown && e.wire == s,
    orElse: () => unknown,
  );
}

enum StokvelRole {
  member('Member'),
  treasurer('Treasurer'),
  unknown('');

  new(this.wire);
  final String wire;
  static StokvelRole fromWire(String? s) => values.firstWhere(
    (e) => e != unknown && e.wire == s,
    orElse: () => unknown,
  );
}

// NEW: demo identities (same people as the API seed)
enum Persona {
  thandi('Thandi Nkosi'),
  sipho('Sipho Dlamini'),
  bongani('Bongani Zulu');

  new(this.displayName);
  final String displayName;
}
