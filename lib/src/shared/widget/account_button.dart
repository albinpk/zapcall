import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/providers/app_user_provider.dart';
import 'package:zapcall/src/router/routes.dart';

class AccountButton extends ConsumerWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).requireValue!;
    return TextButton.icon(
      onPressed: () => _onLogout(ref),
      icon: const Icon(Icons.account_circle_rounded),
      label: Text(user.name),
    );
  }

  Future<void> _onLogout(WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
          context: ref.context,
          builder: (context) {
            return AlertDialog(
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('No'),
                ),
                FilledButton(
                  child: const Text('Yes'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout) return;

    final user = FirebaseAuth.instance.currentUser!;
    unawaited(Db.usersRef.doc(user.uid).delete());
    unawaited(FirebaseAuth.instance.signOut());
    if (ref.context.mounted) const LoginRoute().go(ref.context);
  }
}
