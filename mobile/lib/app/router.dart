import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:ronditrack/app/routes.dart';
import 'package:ronditrack/core/session/session.dart';
import 'package:ronditrack/features/auth/application/auth_flow.dart';

part 'router.g.dart';

/// The router re-runs the redirect whenever the auth state changes, not only
/// when someone taps. UPDATED 11.2: it also listens to the restoring/signed-in status.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authProvider, (_, _) => refresh.value++)
    ..listen(authFlowProvider, (_, _) => refresh.value++);
  final router = createRouter(
    isSignedIn: () => ref.read(authProvider) != null,
    isRestoring: () => ref.read(authFlowProvider) is Restoring,
    refreshListenable: refresh,
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
}
