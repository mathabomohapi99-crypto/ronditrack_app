import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ronditrack/app/not_found_screen.dart';
import 'package:ronditrack/app/redirect.dart';
import 'package:ronditrack/app/shell.dart';
import 'package:ronditrack/features/activity/presentation/activity_screen.dart';
import 'package:ronditrack/features/auth/presentation/sign_in_screen.dart';
import 'package:ronditrack/features/auth/presentation/splash_screen.dart';
import 'package:ronditrack/features/home/presentation/home_screen.dart';
import 'package:ronditrack/features/join/presentation/join_screen.dart';
import 'package:ronditrack/features/payout/presentation/payouts_screen.dart';
import 'package:ronditrack/features/profile/presentation/profile_screen.dart';
import 'package:ronditrack/features/stokvel/presentation/cycle_screen.dart';
import 'package:ronditrack/features/stokvel/presentation/stokvel_route_body.dart';
import 'package:ronditrack/features/stokvel/presentation/stokvels_screen.dart';

part 'routes.g.dart';

/// Builds the router. The redirect is the pure function in redirect.dart.
GoRouter createRouter({
  required bool Function() isSignedIn,
  bool Function()? isRestoring,
  Listenable? refreshListenable,
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: refreshListenable,
  routes: $appRoutes,
  redirect: (context, state) => redirectFor(
    signedIn: isSignedIn(),
    restoring: isRestoring?.call() ?? false,
    location: state.uri,
  ),
  errorBuilder: (context, state) => const NotFoundScreen(),
);

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends GoRouteData with $SplashRoute {
  const new({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SplashScreen();
}

@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  const new({this.from});

  final String? from;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SignInScreen(from: from);
}

class JoinRoute extends GoRouteData with $JoinRoute {
  const new({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      JoinScreen(code: code);
}

@TypedStatefulShellRoute<AppShellRoute>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeBranch>(
      routes: <TypedRoute<RouteData>>[
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
        TypedGoRoute<StokvelsRoute>(
          path: '/stokvels',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<StokvelRoute>(
              path: ':id',
              routes: <TypedRoute<RouteData>>[
                TypedGoRoute<CycleRoute>(
                  path: 'cycles/:cycleId',
                  routes: <TypedRoute<RouteData>>[
                    TypedGoRoute<PayoutsRoute>(path: 'payouts'),
                  ],
                ),
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
class AppShellRoute extends StatefulShellRouteData {
  const new();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(navigationShell: navigationShell);
}

class HomeBranch extends StatefulShellBranchData {
  const new();
}

class StokvelsBranch extends StatefulShellBranchData {
  const new();
}

class ActivityBranch extends StatefulShellBranchData {
  const new();
}

class ProfileBranch extends StatefulShellBranchData {
  const new();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class StokvelsRoute extends GoRouteData with $StokvelsRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const StokvelsScreen();
}

/// One page key for every stokvel id: switching stokvel updates this page in
/// place, so the old stokvel's data can never sit under the new name.
class StokvelRoute extends GoRouteData with $StokvelRoute {
  const new({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: const ValueKey('stokvel-detail'),
        child: StokvelRouteBody(stokvelId: id),
      );
}

class CycleRoute extends GoRouteData with $CycleRoute {
  const new({required this.id, required this.cycleId});

  final String id;
  final String cycleId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: const ValueKey('cycle-detail'),
        child: CycleScreen(stokvelId: id, cycleId: cycleId),
      );
}

/// Under its cycle: back goes to the cycle, and a cold-start link builds the
/// stokvel and the cycle underneath it.
class PayoutsRoute extends GoRouteData with $PayoutsRoute {
  const new({required this.id, required this.cycleId});

  final String id;
  final String cycleId;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      MaterialPage<void>(
        key: const ValueKey('payouts'),
        child: PayoutsScreen(stokvelId: id, cycleId: cycleId),
      );
}

class ActivityRoute extends GoRouteData with $ActivityRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ActivityScreen();
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProfileScreen();
}
