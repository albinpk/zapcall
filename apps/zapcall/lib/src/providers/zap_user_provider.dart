import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/user.dart';

part 'zap_user_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<ZapUser> zapUser(Ref ref, String uid) {
  return Db.usersRef.doc(uid).snapshots().map((e) => e.data()!);
}
