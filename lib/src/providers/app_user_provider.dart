import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zapcall/src/data/models/user.dart';
import 'package:zapcall/src/providers/zap_user_provider.dart';

part 'app_user_provider.g.dart';

@riverpod
class AppUser extends _$AppUser {
  @override
  Future<ZapUser?> build() async {
    final sub = FirebaseAuth.instance
        .authStateChanges()
        .skip(1)
        .listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await ref.watch(zapUserProvider(user.uid).future);
  }
}
