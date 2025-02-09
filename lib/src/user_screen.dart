import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zapcall/src/call_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;

  // ignoring first event
  bool _startListen = false;

  void _startListerRooms() {
    sub = db.collection('rooms').snapshots().listen((event) {
      for (final e in event.docChanges) {
        if (!_startListen) {
          _startListen = true;
          return;
        }

        if (e.type == DocumentChangeType.added) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Call from ${e.doc.id}'),
              duration: Duration(seconds: 200),
              action: SnackBarAction(
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: 'Answer',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        roomId: e.doc.id,
                      ),
                    ),
                  );
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
    return Scaffold(
      body: Align(
        alignment: Alignment(0, -0.5),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('ZapCall'),
                centerTitle: true,
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: 1,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Albin'),
                      trailing: IconButton.filledTonal(
                        tooltip: 'Start Video Call',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CallScreen(roomId: null),
                            ),
                          );
                        },
                        icon: Icon(Icons.videocam_outlined),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
