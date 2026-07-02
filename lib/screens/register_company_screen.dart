import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterCompanyScreen extends StatefulWidget {
  const RegisterCompanyScreen({super.key});

  @override
  State<RegisterCompanyScreen> createState() => _RegisterCompanyScreenState();
}

class _RegisterCompanyScreenState extends State<RegisterCompanyScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  final companyNameController = TextEditingController();
  final vatController = TextEditingController();
  final addressController = TextEditingController();
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  Future<void> registerCompany() async {
    if (isLoading) return;

    final companyName = companyNameController.text.trim();
    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (companyName.isEmpty ||
        firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        errorMessage = "Veuillez remplir tous les champs obligatoires.";
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = "Le mot de passe doit contenir au moins 6 caractères.";
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = "Les mots de passe ne correspondent pas.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://taskflowapp.eu/auth/register_company.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_name": companyName,
          "company_email": email,
          "company_phone": phoneController.text.trim(),
          "vat_number": vatController.text.trim(),
          "address": addressController.text.trim(),
          "firstname": firstname,
          "lastname": lastname,
          "email": email,
          "phone": phoneController.text.trim(),
          "password": password,
          "app": "pointagepro",
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (data["success"] == true) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text("Entreprise créée"),
            content: Text(
              data["message"] ??
                  "Votre entreprise a bien été créée. Veuillez vérifier vos emails et cliquer sur le lien d'activation avant de vous connecter.",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Connexion"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      } else {
        setState(() {
          errorMessage = data["message"] ?? "Impossible de créer l'entreprise.";
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Erreur de connexion au serveur.";
      });
    }
  }

  @override
  void dispose() {
    companyNameController.dispose();
    vatController.dispose();
    addressController.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Créer une entreprise"),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -90,
              child: _BlurCircle(size: 270, color: blue.withOpacity(0.20)),
            ),
            Positioned(
              bottom: -130,
              left: -100,
              child: _BlurCircle(size: 290, color: purple.withOpacity(0.15)),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              children: [
                const Icon(
                  CupertinoIcons.building_2_fill,
                  color: blue,
                  size: 54,
                ),
                const SizedBox(height: 14),
                const Text(
                  "Créer votre entreprise",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Configurez PointagePro pour gérer les pointages, QR Codes, plannings et présences de votre équipe.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                _GlassCard(
                  child: Column(
                    children: [
                      _GlassTextField(
                        controller: companyNameController,
                        placeholder: "Nom de l'entreprise *",
                        icon: CupertinoIcons.building_2_fill,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: vatController,
                        placeholder: "Numéro TVA",
                        icon: CupertinoIcons.doc_text_fill,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: addressController,
                        placeholder: "Adresse",
                        icon: CupertinoIcons.location_solid,
                      ),
                      const SizedBox(height: 18),

                      _GlassTextField(
                        controller: firstnameController,
                        placeholder: "Prénom du responsable *",
                        icon: CupertinoIcons.person_fill,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: lastnameController,
                        placeholder: "Nom du responsable *",
                        icon: CupertinoIcons.person_fill,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: emailController,
                        placeholder: "Email *",
                        icon: CupertinoIcons.mail_solid,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: phoneController,
                        placeholder: "Téléphone",
                        icon: CupertinoIcons.phone_fill,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),

                      _GlassTextField(
                        controller: passwordController,
                        placeholder: "Mot de passe *",
                        icon: CupertinoIcons.lock_fill,
                        obscureText: obscurePassword,
                      ),
                      const SizedBox(height: 14),
                      _GlassTextField(
                        controller: confirmPasswordController,
                        placeholder: "Confirmer le mot de passe *",
                        icon: CupertinoIcons.lock_fill,
                        obscureText: obscurePassword,
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
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
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: red,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isLoading ? null : registerCompany,
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
                                : const Text(
                                    "Créer mon entreprise",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
  });

  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      placeholder: placeholder,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(icon, color: _RegisterCompanyScreenState.blue, size: 22),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.84),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.65)),
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
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
