import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import 'main_tab_screen.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color red = Color(0xFFFF3B30);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Veuillez entrer votre email et votre mot de passe.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success = await AuthService.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

if (success) {
  TextInput.finishAutofillContext(shouldSave: true);

  Navigator.pushReplacement(
    context,
    CupertinoPageRoute(builder: (_) => const MainTabScreen()),
  );
} else {
      setState(() {
        errorMessage = "Email ou mot de passe incorrect.";
      });
    }
  }

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage =
            "Veuillez d'abord entrer votre adresse email pour réinitialiser le mot de passe.";
      });
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text("Mot de passe oublié"),
        content: Text(
          "Une demande de réinitialisation sera envoyée pour :\n\n$email",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Fermer"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

   
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success = await AuthService.forgotPassword(email: email);

    if (!mounted) return;

    setState(() {
      isLoading = false;
      errorMessage = success
          ? "Un email de réinitialisation a été envoyé."
          : "Impossible d'envoyer l'email de réinitialisation.";
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: background,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _BlurCircle(
                size: 270,
                color: blue.withOpacity(0.22),
              ),
            ),
            Positioned(
              top: 260,
              left: -130,
              child: _BlurCircle(
                size: 290,
                color: purple.withOpacity(0.16),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -90,
              child: _BlurCircle(
                size: 280,
                color: green.withOpacity(0.13),
              ),
            ),

            Center(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 16),

                  _LogoHeader(),

                  const SizedBox(height: 30),

                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Connexion",
                          style: TextStyle(
                            color: text,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Connectez-vous avec votre compte entreprise.",
                          style: TextStyle(
                            color: subtitle,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 24),

 AutofillGroup(
  child: Column(
    children: [
      _GlassTextField(
        controller: emailController,
        placeholder: "Email",
        icon: CupertinoIcons.mail_solid,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [
          AutofillHints.username,
          AutofillHints.email,
        ],
        textInputAction: TextInputAction.next,
      ),

      const SizedBox(height: 14),

      _GlassTextField(
        controller: passwordController,
        placeholder: "Mot de passe",
        icon: CupertinoIcons.lock_fill,
        obscureText: obscurePassword,
        autofillHints: const [
          AutofillHints.password,
        ],
        textInputAction: TextInputAction.done,
        suffix: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 34,
          onPressed: () {
            setState(() {
              obscurePassword = !obscurePassword;
            });
          },
          child: Icon(
            obscurePassword
                ? CupertinoIcons.eye_fill
                : CupertinoIcons.eye_slash_fill,
            color: subtitle,
            size: 22,
          ),
        ),
      ),
    ],
  ),
),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 34,
                            onPressed: isLoading ? null : forgotPassword,
                            child: const Text(
                              "Mot de passe oublié ?",
                              style: TextStyle(
                                color: blue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: red.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: red,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: isLoading ? null : login,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [blue, purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: blue.withOpacity(0.24),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isLoading
                                  ? const CupertinoActivityIndicator(
                                      color: Colors.white,
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_right_circle_fill,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Connexion",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "PointagePro • Pointage & présence équipe",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subtitle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 88,
          width: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _LoginScreenState.blue,
                _LoginScreenState.purple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _LoginScreenState.blue.withOpacity(0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.clock_fill,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "PointagePro",
          style: TextStyle(
            color: _LoginScreenState.text,
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Gestion moderne des présences",
          style: TextStyle(
            color: _LoginScreenState.subtitle,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.autofillHints,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      placeholder: placeholder,
      placeholderStyle: const TextStyle(
        color: _LoginScreenState.subtitle,
        fontWeight: FontWeight.w500,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(
          icon,
          color: _LoginScreenState.blue,
          size: 22,
        ),
      ),
      suffix: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffix,
            ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}