import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const PointageProApp());
}

class PointageProApp extends StatelessWidget {
  const PointageProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'PointagePro',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF007AFF),
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: const LoginScreen(),
    );
  }
}
