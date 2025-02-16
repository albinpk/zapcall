import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/room.dart';
import 'package:zapcall/src/providers/app_user_provider.dart';

class RoomTile extends ConsumerWidget {
  const RoomTile({
    required this.room,
    super.key,
  });

  final QueryDocumentSnapshot<RoomModel> room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(appUserProvider).requireValue!.id;
    final room = this.room.data();
    return ListTile(
      // title: Text(room.info.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (room.info.fromId == userId)
            IconButton(
              onPressed: _onDelete,
              color: Colors.red,
              icon: const Icon(Icons.delete_outline),
            ),
          FilledButton.tonal(
            onPressed: () {
              // const CallRoute(roomId: null).push<void>(context);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDelete() async {
    await Db.roomsRef.doc(room.id).delete();
  }
}
