import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zapcall/src/call_screen.dart';
import 'package:zapcall/src/modules/auth/login/login_screen.dart';
import 'package:zapcall/src/modules/rooms/rooms_screen.dart';
import 'package:zapcall/src/shared/widget/navigation_view.dart';
import 'package:zapcall/src/user_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

@TypedStatefulShellRoute<ShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<UsersRoute>(path: '/users'),
      ],
    ),
    // TypedStatefulShellBranch(
    //   routes: [
    //     TypedGoRoute<RoomsRoute>(path: '/rooms'),
    //   ],
    // ),
  ],
)
class ShellRouteData extends StatefulShellRouteData {
  const ShellRouteData();

  // static final GlobalKey<NavigatorState> $navigatorKey = shellNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return NavigationView(navigationShell: navigationShell);
  }
}

class UsersRoute extends GoRouteData {
  const UsersRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(child: UsersScreen());
  }
}

// TODO(albin): hidden
class RoomsRoute extends GoRouteData {
  const RoomsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return const NoTransitionPage(child: RoomsScreen());
  }
}

@TypedGoRoute<CallRoute>(path: '/call')
class CallRoute extends GoRouteData {
  const CallRoute({
    this.userId,
    this.roomId,
  }) : assert(
          userId != null || roomId != null,
          'Either userId or roomId must be provided',
        );

  final String? userId;
  final String? roomId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    if (userId != null) return CallScreen.call(userId: userId!);
    return CallScreen.answer(roomId: roomId!);
  }
}
