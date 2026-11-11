// NEW 10.2: theme extension with status tokens Material does not have; each has a light AND a dark pair
import 'package:flutter/material.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';

@immutable
class Tone {
  const Tone(this.foreground, this.background);
  final Color foreground;
  final Color background;

  static Tone lerp(Tone a, Tone b, double t) => Tone(
    Color.lerp(a.foreground, b.foreground, t)!,
    Color.lerp(a.background, b.background, t)!,
  );
}

@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.pending,
    required this.paid,
    required this.confirmed,
    required this.unknown,
    required this.open,
    required this.closed,
    required this.paidOut,
    required this.arrears,
  });

  final Tone pending;
  final Tone paid;
  final Tone confirmed;
  final Tone unknown;
  final Tone open;
  final Tone closed;
  final Tone paidOut;
  final Tone arrears;

  // LIGHT
  static const light = StatusColors(
    pending: Tone(Color(0xFF3E2723), Color(0xFFFFE082)),
    paid: Tone(Color(0xFF0D47A1), Color(0xFFBBDEFB)),
    confirmed: Tone(Color(0xFF1B5E20), Color(0xFFC8E6C9)),
    unknown: Tone(Color(0xFF212121), Color(0xFFE0E0E0)),
    open: Tone(Color(0xFF004D40), Color(0xFFB2DFDB)),
    closed: Tone(Color(0xFF3E2723), Color(0xFFD7CCC8)),
    paidOut: Tone(Color(0xFF4A148C), Color(0xFFE1BEE7)),
    arrears: Tone(Color(0xFF9B1C1C), Color(0xFFFFCDD2)),
  );

  // DARK
  static const dark = StatusColors(
    pending: Tone(Color(0xFFFFE082), Color(0xFF5D4037)),
    paid: Tone(Color(0xFF90CAF9), Color(0xFF1A3A5C)),
    confirmed: Tone(Color(0xFFA5D6A7), Color(0xFF1B3D1F)),
    unknown: Tone(Color(0xFFE0E0E0), Color(0xFF3A3A3A)),
    open: Tone(Color(0xFF80CBC4), Color(0xFF0F3D38)),
    closed: Tone(Color(0xFFD7CCC8), Color(0xFF3E2F2B)),
    paidOut: Tone(Color(0xFFCE93D8), Color(0xFF3B1F5C)),
    arrears: Tone(Color(0xFFFFB4A9), Color(0xFF5C1A1A)),
  );

  // Exhaustive: a new status is a compile error here until it gets a colour
  Tone forContribution(ContributionStatus s) => switch (s) {
    ContributionStatus.pending => pending,
    ContributionStatus.paid => paid,
    ContributionStatus.confirmed => confirmed,
    ContributionStatus.unknown => unknown,
  };

  Tone forCycle(CycleStatus s) => switch (s) {
    CycleStatus.open => open,
    CycleStatus.closed => closed,
    CycleStatus.paidOut => paidOut,
    CycleStatus.unknown => unknown,
  };

  @override
  StatusColors copyWith({
    Tone? pending,
    Tone? paid,
    Tone? confirmed,
    Tone? unknown,
    Tone? open,
    Tone? closed,
    Tone? paidOut,
    Tone? arrears,
  }) => StatusColors(
    pending: pending ?? this.pending,
    paid: paid ?? this.paid,
    confirmed: confirmed ?? this.confirmed,
    unknown: unknown ?? this.unknown,
    open: open ?? this.open,
    closed: closed ?? this.closed,
    paidOut: paidOut ?? this.paidOut,
    arrears: arrears ?? this.arrears,
  );

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      pending: Tone.lerp(pending, other.pending, t),
      paid: Tone.lerp(paid, other.paid, t),
      confirmed: Tone.lerp(confirmed, other.confirmed, t),
      unknown: Tone.lerp(unknown, other.unknown, t),
      open: Tone.lerp(open, other.open, t),
      closed: Tone.lerp(closed, other.closed, t),
      paidOut: Tone.lerp(paidOut, other.paidOut, t),
      arrears: Tone.lerp(arrears, other.arrears, t),
    );
  }
}

extension StatusColorsContext on BuildContext {
  // Widgets ask for "arrears", never for a red; falls back to light when a test has no theme
  StatusColors get statusColors =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}
