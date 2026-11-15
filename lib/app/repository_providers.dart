// UPDATED 10.3: the ONLY file Week 11 changes: one provider per repository names the implementation (payouts added)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/features/payouts/data/fake_payout_repository.dart';
import 'package:ronditrack/features/payouts/domain/payout_repository.dart';
import 'package:ronditrack/features/stokvels/data/fake_repositories.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/domain/repositories.dart';

part 'repository_providers.g.dart';

@Riverpod(keepAlive: true)
class CurrentPersona extends _$CurrentPersona {
  @override
  Persona build() => Persona.thandi;
  // Public method (not a public field) so riverpod_lint stays happy
  void select(Persona p) => state = p;
}

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) =>
    FakeHomeRepository(persona: ref.watch(currentPersonaProvider));

@Riverpod(keepAlive: true)
StokvelRepository stokvelRepository(Ref ref) =>
    FakeStokvelRepository(persona: ref.watch(currentPersonaProvider));

@Riverpod(keepAlive: true)
PayoutRepository payoutRepository(Ref ref) =>
    FakePayoutRepository(persona: ref.watch(currentPersonaProvider));
