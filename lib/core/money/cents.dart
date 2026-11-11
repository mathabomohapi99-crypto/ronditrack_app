// NEW: Cents = whole cents as int (Part 2). No double anywhere near money.
extension type const Cents(int value) {
  bool get isNegative => value < 0;
  Cents operator +(Cents other) => Cents(value + other.value);
  Cents operator -(Cents other) => Cents(value - other.value);
}
