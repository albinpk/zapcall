import 'package:flutter/material.dart';
import 'package:zapcall/src/user_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZapCall',
      debugShowCheckedModeBanner: false,
      home: UsersScreen(),
      // darkTheme: ThemeData.dark(),
    );
  }
}
