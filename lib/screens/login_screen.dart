import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'employee/employee_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final codeController = TextEditingController();

  void login() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const EmployeeHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              const Text(
                'PointagePro',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Le pointage simple et sécurisé pour votre équipe.',
                style: TextStyle(fontSize: 17, color: Color(0xFF6B7280)),
              ),

              const SizedBox(height: 50),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: codeController,
                      placeholder: 'Code employé',
                      padding: const EdgeInsets.all(16),
                      keyboardType: TextInputType.number,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(18),
                        onPressed: login,
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              const Center(
                child: Text(
                  'Version employé',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
