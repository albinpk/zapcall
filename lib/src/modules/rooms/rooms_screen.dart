import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/user.dart';
import 'package:zapcall/src/modules/rooms/widget/create_room_dialog.dart';
import 'package:zapcall/src/modules/rooms/widget/create_user_dialog.dart';
import 'package:zapcall/src/modules/rooms/widget/room_tile.dart';
import 'package:zapcall/src/providers/app_user_provider.dart';
import 'package:zapcall/src/providers/rooms_provider.dart';
import 'package:zapcall/src/shared/widget/account_button.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        centerTitle: false,
        actions: [if (user != null) const AccountButton()],
      ),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: () => _onLogin(ref),
                child: const Text('Login'),
              ),
            )
          : ref.watch(roomsProvider).when(
                error: (error, _) => Center(child: Text(error.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text('No rooms found'),
                    );
                  }

                  return ListView.builder(
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return RoomTile(room: room);
                    },
                  );
                },
              ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showCreateRoomDialog(ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Room'),
            ),
    );
  }

  Future<void> _onLogin(WidgetRef ref) async {
    final userName = await showDialog<String>(
      context: ref.context,
      builder: (context) {
        return const CreateUserDialog();
      },
    );

    if (userName == null) return;

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      await Db.usersRef.doc(userCredential.user!.uid).set(
            ZapUser(
              id: userCredential.user!.uid,
              name: userName,
            ),
          );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'operation-not-allowed':
          log("Anonymous auth hasn't been enabled for this project.");
        default:
          log('Unknown error.');
      }
    } catch (e) {
      log(e.toString());
    }

    await FirebaseAuth.instance.currentUser!.updateDisplayName('hello');
  }

  Future<void> _showCreateRoomDialog(WidgetRef ref) async {
    final roomName = await showDialog<String>(
      context: ref.context,
      builder: (context) {
        return const CreateRoomDialog();
      },
    );
    if (roomName == null) return;

    await ref.read(roomsProvider.notifier).createRoom(
          roomName: roomName,
          userId: FirebaseAuth.instance.currentUser!.uid,
        );
  }
}
