import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zapcall/assets.dart';
import 'package:zapcall/src/data/db.dart';
import 'package:zapcall/src/data/models/user.dart';
import 'package:zapcall/src/router/routes.dart';
import 'package:zapcall/src/shared/widget/app_info_dialog.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final enableSave = useState(false);
    final isLoading = useState(false);
    return Scaffold(
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(
              Assets.images.loginBgJPG,
              fit: BoxFit.cover,
            ),
          ),

          // login form
          Center(
            child: SizedBox(
              width: 500,
              child: Card(
                color: Colors.white,
                elevation: 5,
                shadowColor: Colors.black26,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to Zap!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Start your seamless video calls instantly.\n'
                        'Just enter your name and join!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 30),

                      // name input
                      TextField(
                        controller: nameController,
                        onChanged: (value) {
                          enableSave.value = value.trim().isNotEmpty;
                        },
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
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

          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => _showAboutDialog(context),
              icon: const Icon(Icons.info_outline),
            ),
          ),
        ],
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

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const AppInfoDialog(),
    );
  }
}
