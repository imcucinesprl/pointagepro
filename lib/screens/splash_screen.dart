import 'package:flutter/cupertino.dart';

import '../core/services/session_service.dart';
import 'login_screen.dart';
import 'main_tab_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkSession();
  }

  Future<void> checkSession() async {
    final userId = await SessionService.getUserId();

    if (!mounted) return;

    if (userId != null && userId > 0) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MainTabScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: Color(0xFFF2F2F7),
      child: Center(child: CupertinoActivityIndicator(radius: 18)),
    );
  }
}
