// NEW: status mapping, Membership (one login = Treasurer of one, Member of another), actions match
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/actions.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';

void main() {
  test('unknown strings become unknown, never throw', () {
    expect(CycleStatus.fromWire('Archived'), CycleStatus.unknown);
    expect(ContributionStatus.fromWire(null), ContributionStatus.unknown);
    expect(StokvelRole.fromWire('Chair'), StokvelRole.unknown);
    expect(CycleStatus.fromWire('PaidOut'), CycleStatus.paidOut);
  });

  test(
    'Thandi is Treasurer of one stokvel and Member of another (same login)',
    () async {
      final entries = await FakeHomeRepository(
        persona: Persona.thandi,
        delay: Duration.zero,
      ).loadHome();
      final m = [
        for (final e in entries)
          Membership(stokvelId: e.stokvelId, role: e.role),
      ];
      expect(
        m.firstWhere((x) => x.stokvelId == ubuntuId).role,
        StokvelRole.treasurer,
      );
      expect(
        m.firstWhere((x) => x.stokvelId == groceryId).role,
        StokvelRole.member,
      );
    },
  );

  test('actions: one case per rule row', () {
    Set<StokvelAction> a(StokvelRole r, CycleStatus c, ContributionStatus m) =>
        allowedActions((role: r, cycle: c, mine: m));
    expect(
      a(StokvelRole.member, CycleStatus.open, ContributionStatus.pending),
      {StokvelAction.pay, StokvelAction.uploadProof},
    );
    expect(a(StokvelRole.member, CycleStatus.open, ContributionStatus.paid), {
      StokvelAction.uploadProof,
    });
    expect(
      a(StokvelRole.member, CycleStatus.open, ContributionStatus.confirmed),
      isEmpty,
    );
    expect(
      a(StokvelRole.member, CycleStatus.closed, ContributionStatus.pending),
      isEmpty,
    );
    expect(
      a(StokvelRole.treasurer, CycleStatus.open, ContributionStatus.confirmed),
      {StokvelAction.confirmContributions, StokvelAction.closeCycle},
    );
    expect(
      a(
        StokvelRole.treasurer,
        CycleStatus.closed,
        ContributionStatus.confirmed,
      ),
      {StokvelAction.recordPayout},
    );
    expect(
      a(
        StokvelRole.treasurer,
        CycleStatus.paidOut,
        ContributionStatus.confirmed,
      ),
      isEmpty,
    );
  });

  test('Treasurer actions only where Treasurer', () async {
    final repo = FakeStokvelRepository(
      persona: Persona.thandi,
      delay: Duration.zero,
    );
    expect(
      actionsFor(await repo.load(ubuntuId)),
      contains(StokvelAction.closeCycle),
    );
    expect(
      actionsFor(await repo.load(groceryId)),
      isNot(contains(StokvelAction.closeCycle)),
    );
  });

  test('non-member stokvel is NotFound', () async {
    final repo = FakeStokvelRepository(
      persona: Persona.sipho,
      delay: Duration.zero,
    );
    expect(() => repo.load(groceryId), throwsA(isA<Object>()));
  });
}
