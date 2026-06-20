import 'package:flutter/cupertino.dart';

import '../core/services/auth_service.dart';
import 'main_tab_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> login() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success = await AuthService.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MainTabScreen()),
      );
    } else {
      setState(() {
        errorMessage = "Identifiants incorrects.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 50),

              const Text(
                "PointagePro",
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 8),

              const Text(
                "Connecte-toi avec ton compte entreprise.",
                style: TextStyle(fontSize: 17, color: Color(0xFF6B7280)),
              ),

              const SizedBox(height: 40),

              CupertinoTextField(
                controller: emailController,
                placeholder: "Email",
                keyboardType: TextInputType.emailAddress,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              const SizedBox(height: 14),

              CupertinoTextField(
                controller: passwordController,
                placeholder: "Mot de passe",
                obscureText: true,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              const SizedBox(height: 18),

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const SizedBox(height: 18),

              SizedBox(
                height: 54,
                child: CupertinoButton(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(18),
                  onPressed: isLoading ? null : login,
                  child: Text(
                    isLoading ? "Connexion..." : "Se connecter",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
