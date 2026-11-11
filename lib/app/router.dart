// NEW 10.2: typed go_router routes (stateful shell, 4 tabs), the gate wiring, and the router provider
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronditrack/app/app_shell.dart';
import 'package:ronditrack/app/redirect.dart';
import 'package:ronditrack/features/activity/activity_page.dart';
import 'package:ronditrack/features/auth/auth_provider.dart';
import 'package:ronditrack/features/auth/sign_in_page.dart';
import 'package:ronditrack/features/profile/profile_page.dart';
import 'package:ronditrack/features/stokvels/domain/enums.dart';
import 'package:ronditrack/features/stokvels/presentation/cycle_page.dart';
import 'package:ronditrack/features/stokvels/presentation/home_page.dart';
import 'package:ronditrack/features/stokvels/presentation/join_page.dart';
import 'package:ronditrack/features/stokvels/presentation/not_found_view.dart';
import 'package:ronditrack/features/stokvels/presentation/stokvels_screen.dart';

part 'router.g.dart';

@TypedStatefulShellRoute<AppShellData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeBranch>(
      routes: <TypedRoute<RouteData>>[
        // /join/:code sits UNDER Home so back from a cold-start link lands on Home
        TypedGoRoute<HomeRoute>(
          path: '/',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<JoinRoute>(path: 'join/:code'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<StokvelsBranch>(
      routes: <TypedRoute<RouteData>>[
        // list > stokvel > cycle: opening a cycle builds the stokvel (and list) underneath
        TypedGoRoute<StokvelsRoute>(
          path: '/stokvels',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<StokvelRoute>(
              path: ':id',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<CycleRoute>(path: 'cycles/:cycleId'),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<ActivityBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ActivityRoute>(path: '/activity'),
      ],
    ),
    TypedStatefulShellBranch<ProfileBranch>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ProfileRoute>(path: '/profile'),
      ],
    ),
  ],
)
class AppShellData extends StatefulShellRouteData {
  const AppShellData();

  static Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(shell: navigationShell);
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class StokvelsBranch extends StatefulShellBranchData {
  const StokvelsBranch();
}

class ActivityBranch extends StatefulShellBranchData {
  const ActivityBranch();
}

class ProfileBranch extends StatefulShellBranchData {
  const ProfileBranch();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

class JoinRoute extends GoRouteData with $JoinRoute {
  const JoinRoute({required this.code});
  final String code;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JoinPage(code: code);
}

class StokvelsRoute extends GoRouteData with $StokvelsRoute {
  const StokvelsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StokvelsScreen();
}

class StokvelRoute extends GoRouteData with $StokvelRoute {
  const StokvelRoute({required this.id});
  final String id;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      StokvelScreen(stokvelId: id);
}

class CycleRoute extends GoRouteData with $CycleRoute {
  const CycleRoute({required this.id, required this.cycleId});
  final String id;
  final String cycleId;
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CyclePage(stokvelId: id, cycleId: cycleId);
}

class ActivityRoute extends GoRouteData with $ActivityRoute {
  const ActivityRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ActivityPage();
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfilePage();
}

@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  const SignInRoute({this.from});
  final String? from;
  @override
  Widget build(BuildContext context, GoRouterState state) => const SignInPage();
}

// Tells GoRouter to re-run the redirect whenever the auth state changes (not only on taps)
class _AuthRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

GoRouter createRouter({
  required Persona? Function() readUser,
  required Listenable refreshListenable,
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  routes: $appRoutes,
  refreshListenable: refreshListenable,
  redirect: (context, state) => redirectFor(user: readUser(), uri: state.uri),
  errorBuilder: (context, state) => const NotFoundView(),
);

// Tests override this to start from a deep link
final initialLocationProvider = Provider<String>((ref) => '/');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh();
  ref.listen(authProvider, (_, _) => refresh.ping());
  final router = createRouter(
    readUser: () => ref.read(authProvider),
    refreshListenable: refresh,
    initialLocation: ref.read(initialLocationProvider),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
