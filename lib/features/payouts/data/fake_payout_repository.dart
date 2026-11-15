// NEW 10.3: fake payout orders for the seed personas. Non-members and wrong cycles get "not found", like the API's 404
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/payouts/domain/payout_models.dart';
import 'package:ronditrack/features/payouts/domain/payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_status.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

const ubuntuCycle3 = 'ubuntu-cycle-3';
const ubuntuCycle4 = 'ubuntu-cycle-4';
const groceryCycle2 = 'grocery-cycle-2';

PayoutEntry _p(
  String id,
  String name,
  int position,
  int cents,
  DateTime date,
  PayoutStatus s,
) => PayoutEntry(
  id: id,
  memberName: name,
  position: position,
  amount: Cents(cents),
  payoutDate: date,
  status: s,
);

// What the server would send: stokvel id -> cycle id -> order (the server's order, the server's "Next")
final _orders = <String, Map<String, List<PayoutEntry>>>{
  ubuntuId: {
    ubuntuCycle3: [
      _p('u3-1', 'Thandi Nkosi', 1, 150000, DateTime(2026, 10, 31), PayoutStatus.paid),
      _p('u3-2', 'Sipho Dlamini', 2, 150000, DateTime(2026, 11, 30), PayoutStatus.next),
      _p('u3-3', 'Lerato Mokoena', 3, 150000, DateTime(2026, 12, 31), PayoutStatus.waiting),
    ],
    ubuntuCycle4: <PayoutEntry>[], // a cycle with no payout order yet
  },
  groceryId: {
    groceryCycle2: [
      _p('g2-1', 'Kagiso Molefe', 1, 75000, DateTime(2026, 10, 31), PayoutStatus.paid),
      _p('g2-2', 'Thandi Nkosi', 2, 75000, DateTime(2026, 11, 14), PayoutStatus.next),
      _p('g2-3', 'Naledi Khumalo', 3, 75000, DateTime(2026, 12, 5), PayoutStatus.waiting),
    ],
  },
};

// Which stokvels each person belongs to (same people as the other fakes)
Set<String> _stokvelsOf(Persona p) => switch (p) {
  Persona.thandi => {ubuntuId, groceryId},
  Persona.sipho => {ubuntuId},
  Persona.bongani => <String>{},
};

class FakePayoutRepository implements PayoutRepository {
  const FakePayoutRepository({
    required this.persona,
    this.delay = const Duration(milliseconds: 600),
  });
  final Persona persona;
  final Duration delay; // a test sets Duration.zero

  @override
  Future<List<PayoutEntry>> loadPayoutOrder({
    required String stokvelId,
    required String cycleId,
  }) async {
    await Future<void>.delayed(delay);
    // One answer for: not my stokvel, no such stokvel, or a cycle of another stokvel
    final order = _stokvelsOf(persona).contains(stokvelId) ? _orders[stokvelId]?[cycleId] : null;
    if (order == null) throw const NotFoundException();
    return order;
  }
}
