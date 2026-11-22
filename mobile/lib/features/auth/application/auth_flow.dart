// NEW 11.2: sealed auth status (signed out / signed in / restoring) and the flow that moves between them
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/core/network/api_mode.dart';
import 'package:ronditrack/core/session/refresh_session.dart';
import 'package:ronditrack/core/session/session.dart';
import 'package:ronditrack/core/session/session_providers.dart';

part 'auth_flow.g.dart';

sealed class AuthStatus {
  const new();
}

final class SignedOut extends AuthStatus {
  const new();
}

final class SignedIn extends AuthStatus {
  const new();
}

/// A refresh token is stored but nobody knows yet if it is still good.
/// offline = we could not reach the API: still signed in, with Try again and Sign out.
final class Restoring extends AuthStatus {
  const new({this.offline = false});

  final bool offline;
}

@Riverpod(keepAlive: true)
class AuthFlow extends _$AuthFlow {
  @override
  AuthStatus build() {
    // On the fakes there is nothing to restore
    if (ref.read(useFakesProvider)) return const SignedOut();
    ref.read(refreshSessionProvider).onEnded = () {
      ref.read(authProvider.notifier).signOut();
      ref.invalidate(currentPersonaProvider);
      state = const SignedOut();
    };
    unawaited(Future<void>.microtask(restore));
    return const Restoring();
  }

  /// One refresh on launch (also used by "Try again" on the offline splash).
  Future<void> restore() async {
    state = const Restoring();
    final result = await ref.read(refreshSessionProvider).restore();
    switch (result) {
      case RestoreResult.signedIn:
        final email =
            await ref.read(refreshTokenStoreProvider).readEmail() ?? '';
        ref
            .read(authProvider.notifier)
            .signInAs(personaIdForEmail(email) ?? email);
        state = const SignedIn();
      case RestoreResult.signedOut:
        state = const SignedOut();
      case RestoreResult.offline:
        state = const Restoring(offline: true);
    }
  }

  Future<void> signIn(String email, String password) async {
    final auth = ref.read(authProvider.notifier);
    if (ref.read(useFakesProvider)) {
      if (!auth.signInWithEmail(email)) {
        throw const SignInException('We do not recognise that email.');
      }
      state = const SignedIn();
      return;
    }
    final clean = email.trim().toLowerCase();
    await ref.read(refreshSessionProvider).login(clean, password);
    auth.signInAs(personaIdForEmail(clean) ?? clean);
    state = const SignedIn();
  }

  /// Wipes the phone FIRST (memory, storage, who is signed in), then tells the API in the background.
  Future<void> signOut() async {
    Future<void>? wipe;
    if (!ref.read(useFakesProvider)) {
      wipe = ref.read(refreshSessionProvider).signOut();
    }
    ref.read(authProvider.notifier).signOut();
    ref.invalidate(currentPersonaProvider);
    state = const SignedOut();
    if (wipe != null) await wipe;
  }
}
