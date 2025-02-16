import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zapcall/src/router/routes.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final isLogged = FirebaseAuth.instance.currentUser != null;
  return GoRouter(
    initialLocation:
        isLogged ? const UsersRoute().location : const LoginRoute().location,
    routes: $appRoutes,
    redirect: (context, state) {
      if (FirebaseAuth.instance.currentUser == null) {
        return const LoginRoute().location;
      }
      if (state.uri.toString() == '/') {
        return const UsersRoute().location;
      }
      return null;
    },
  );
}
