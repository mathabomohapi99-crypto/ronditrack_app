// NEW 10.2: fake auth state: signed out (null) or signed in as a seed persona. Week 11 swaps the inside, the gate stays
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/repository_providers.dart';
import 'package:ronditrack/features/activity/activity_provider.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/presentation/providers.dart';

part 'auth_provider.g.dart';

// Fake directory: email -> persona
Persona? personaForEmail(String email) => switch (email.trim().toLowerCase()) {
  'thandi.nkosi@example.com' => Persona.thandi,
  'sipho.dlamini@example.com' => Persona.sipho,
  'bongani.zulu@example.com' => Persona.bongani,
  _ => null,
};

String emailForPersona(Persona p) => switch (p) {
  Persona.thandi => 'thandi.nkosi@example.com',
  Persona.sipho => 'sipho.dlamini@example.com',
  Persona.bongani => 'bongani.zulu@example.com',
};

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Persona? build() => null;

  bool signInWithEmail(String email) {
    final p = personaForEmail(email);
    if (p == null) return false;
    ref.read(currentPersonaProvider.notifier).select(p);
    state = p;
    return true;
  }

  // Clears everything kept for this person so the next one on a shared phone sees nothing
  void signOut() {
    state = null;
    ref
      ..invalidate(currentPersonaProvider)
      ..invalidate(homeProvider)
      ..invalidate(stokvelDetailProvider)
      ..invalidate(activityProvider);
  }
}
