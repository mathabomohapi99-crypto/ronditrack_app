// NEW 10.3: fake layer: a member gets the order as seeded; anyone else gets "not found"
import 'package:flutter_test/flutter_test.dart';
import 'package:ronditrack/features/payouts/data/fake_payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

void main() {
  FakePayoutRepository repo(Persona p) =>
      FakePayoutRepository(persona: p, delay: Duration.zero);

  test('a member gets the order as seeded', () async {
    final order = await repo(Persona.thandi)
        .loadPayoutOrder(stokvelId: ubuntuId, cycleId: ubuntuCycle3);
    expect(
      [for (final e in order) e.memberName],
      ['Thandi Nkosi', 'Sipho Dlamini', 'Lerato Mokoena'],
    );
    expect(
      [for (final e in order) e.status],
      [PayoutStatus.paid, PayoutStatus.next, PayoutStatus.waiting],
    );
  });

  test('a non-member gets not found, exactly like the API 404', () async {
    await expectLater(
      repo(Persona.sipho)
          .loadPayoutOrder(stokvelId: groceryId, cycleId: groceryCycle2),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      repo(Persona.bongani)
          .loadPayoutOrder(stokvelId: ubuntuId, cycleId: ubuntuCycle3),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('a cycle that belongs to another stokvel is not found too', () async {
    await expectLater(
      repo(Persona.thandi)
          .loadPayoutOrder(stokvelId: ubuntuId, cycleId: groceryCycle2),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('a cycle with no order yet is an empty list, not an error', () async {
    final order = await repo(Persona.thandi)
        .loadPayoutOrder(stokvelId: ubuntuId, cycleId: ubuntuCycle4);
    expect(order, isEmpty);
  });
}
