import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapcall/src/data/models/room.dart';
import 'package:zapcall/src/data/models/user.dart';

abstract class Db {
  static final db = FirebaseFirestore.instance;

  static final usersRef = db.collection('users').withConverter(
        fromFirestore: (snapshot, _) => ZapUser.fromJson(snapshot.data()!),
        toFirestore: (value, _) => value.toJson(),
      );

  static final roomsRef = db.collection('rooms').withConverter(
        fromFirestore: (snapshot, _) => RoomModel.fromJson(snapshot.data()!),
        toFirestore: (value, _) => value.toJson(),
      );
}
