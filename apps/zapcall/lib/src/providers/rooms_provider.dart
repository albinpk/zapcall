import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/room.dart';

part 'rooms_provider.g.dart';

@riverpod
class Rooms extends _$Rooms {
  @override
  Stream<List<QueryDocumentSnapshot<RoomModel>>> build() {
    return Db.roomsRef.snapshots().map((event) {
      return event.docs.map((e) => e).toList();
    });
  }

  Future<void> createRoom({
    required String roomName,
    required String userId,
  }) async {
    await Db.roomsRef.add(
      RoomModel(
        // TODO(albin):
        info: RoomInfoModel(
          // name: roomName,
          fromId: userId,
          toId: '',
        ),
      ),
    );
  }
}
