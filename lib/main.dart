import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'core/services/session_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_tab_screen.dart';

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _checkLoginState() async {
    return SessionService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (snapshot.data == true) {
          return const MainTabScreen();
        }

        return const LoginScreen();
      },
    );
  }
}