// NEW: fake repositories holding the 3 seed personas (Thandi = Treasurer in Ubuntu + Member in Festive; Sipho; Bongani = none)
import 'package:ronditrack/core/money/cents.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/models.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

const ubuntuId = '20000000-0000-0000-0000-000000000001';
const groceryId = '20000000-0000-0000-0000-000000000002';

List<HomeEntry> _home(Persona p) => switch (p) {
  Persona.thandi => [
    HomeEntry(
      stokvelId: ubuntuId,
      name: 'Ubuntu Savers',
      role: StokvelRole.treasurer,
      paid: const Cents(50000),
      owed: const Cents(0),
      arrears: const Cents(0),
      nextPayout: DateTime(2026, 12),
    ),
    HomeEntry(
      stokvelId: groceryId,
      name: 'Festive Grocery Club',
      role: StokvelRole.member,
      paid: const Cents(0),
      owed: const Cents(25000),
      arrears: const Cents(25000),
      nextPayout: DateTime(2026, 12, 5),
    ),
  ],
  Persona.sipho => [
    HomeEntry(
      stokvelId: ubuntuId,
      name: 'Ubuntu Savers',
      role: StokvelRole.member,
      paid: const Cents(50000),
      owed: const Cents(0),
      arrears: const Cents(0),
      nextPayout: DateTime(2026, 12),
    ),
  ],
  Persona.bongani => <HomeEntry>[],
};

ContributionItem _c(
  String id,
  String name,
  int cents,
  ContributionStatus s,
  String me,
) => ContributionItem(
  id: id,
  memberName: name,
  amount: Cents(cents),
  status: s,
  isMine: name == me,
);

StokvelDetail _ubuntu(StokvelRole role, String me) => StokvelDetail(
  stokvelId: ubuntuId,
  name: 'Ubuntu Savers',
  role: role,
  cycle: CycleInfo(
    id: 'ubuntu-cycle-3',
    number: 3,
    status: CycleStatus.open,
    dueDate: DateTime(2026, 11, 30),
  ),
  contributions: [
    _c('1', 'Thandi Nkosi', 50000, ContributionStatus.confirmed, me),
    _c('2', 'Sipho Dlamini', 50000, ContributionStatus.paid, me),
    _c('3', 'Lerato Mokoena', 50000, ContributionStatus.pending, me),
  ],
);

StokvelDetail _grocery(StokvelRole role, String me) => StokvelDetail(
  stokvelId: groceryId,
  name: 'Festive Grocery Club',
  role: role,
  cycle: CycleInfo(
    id: 'grocery-cycle-2',
    number: 2,
    status: CycleStatus.open,
    dueDate: DateTime(2026, 11, 14),
  ),
  contributions: [
    _c('4', 'Kagiso Molefe', 25000, ContributionStatus.confirmed, me),
    _c('5', 'Thandi Nkosi', 25000, ContributionStatus.pending, me),
    _c('6', 'Naledi Khumalo', 25000, ContributionStatus.pending, me),
  ],
);

Map<String, StokvelDetail> _details(Persona p) => switch (p) {
  Persona.thandi => {
    ubuntuId: _ubuntu(StokvelRole.treasurer, p.displayName),
    groceryId: _grocery(StokvelRole.member, p.displayName),
  },
  Persona.sipho => {ubuntuId: _ubuntu(StokvelRole.member, p.displayName)},
  Persona.bongani => <String, StokvelDetail>{},
};

class FakeHomeRepository implements HomeRepository {
  new({required this.persona, this.delay = const Duration(milliseconds: 600)});
  final Persona persona;
  final Duration delay; // a test sets Duration.zero
  @override
  Future<List<HomeEntry>> loadHome() async {
    await Future<void>.delayed(delay);
    return _home(persona);
  }
}

class FakeStokvelRepository implements StokvelRepository {
  new({required this.persona, this.delay = const Duration(milliseconds: 600)});
  final Persona persona;
  final Duration delay;
  @override
  Future<StokvelDetail> load(String stokvelId) async {
    // Festive is "slow on a data bundle" so the stokvel switch is visible on a phone
    await Future<void>.delayed(stokvelId == groceryId ? delay * 5 : delay);
    final d = _details(persona)[stokvelId];
    if (d == null) throw const NotFoundException(); // same as the API's 404 for non-member AND missing
    return d;
  }
}
