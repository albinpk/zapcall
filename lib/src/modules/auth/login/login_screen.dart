import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/user.dart';
import 'package:zapcall/src/router/routes.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final enableSave = useState(false);
    final isLoading = useState(false);
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          child: Card.outlined(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Login',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    onChanged: (value) {
                      enableSave.value = value.trim().isNotEmpty;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: enableSave.value
                          ? () async {
                              isLoading.value = true;
                              enableSave.value = false;
                              await _onLogin(nameController.text.trim());
                              if (context.mounted) {
                                const UsersRoute().go(context);
                              }
                            }
                          : null,
                      child: isLoading.value
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin(String userName) async {
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
  }
}
