import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/user.dart';

part 'users_provider.g.dart';

@riverpod
Stream<List<QueryDocumentSnapshot<ZapUser>>> users(Ref ref) {
  return Db.usersRef
      .where('id', isNotEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .snapshots()
      .map((event) => event.docs);
}
