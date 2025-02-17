import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/room.dart';
import 'package:zapcall/src/data/models/user.dart';
import 'package:zapcall/src/providers/app_user_provider.dart';
import 'package:zapcall/src/providers/users_provider.dart';
import 'package:zapcall/src/providers/zap_user_provider.dart';
import 'package:zapcall/src/router/routes.dart';
import 'package:zapcall/src/shared/widget/account_button.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _startListerRooms();
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  StreamSubscription<QuerySnapshot<RoomModel>>? sub;

  void _startListerRooms() {
    sub = Db.roomsRef
        .where('info.toId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        // .skip(1)
        .listen((event) async {
      if (!mounted) return;
      for (final e in event.docChanges) {
        if (e.type == DocumentChangeType.added) {
          if (!mounted) return;
          final user =
              await ref.read(zapUserProvider(e.doc.data()!.info.fromId).future);
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Incoming call from ${user.name}'),
                duration: const Duration(seconds: 200),
                action: SnackBarAction(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  label: 'Answer',
                  onPressed: () {
                    CallRoute(roomId: e.doc.id).push<void>(context);
                  },
                ),
              ),
            );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(appUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        centerTitle: false,
        actions: [if (appUser != null) const AccountButton()],
      ),
      body: ref.watch(usersProvider).when(
            error: (error, _) => Center(child: Text(error.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text('No users found'),
                );
              }

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final user = data[index].data();
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.name),
                    trailing: IconButton.filledTonal(
                      tooltip: 'Video Call',
                      onPressed: () => _onCall(user),
                      icon: const Icon(Icons.videocam_outlined),
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  void _onCall(ZapUser user) {
    CallRoute(userId: user.id).push<void>(context);
  }
}
