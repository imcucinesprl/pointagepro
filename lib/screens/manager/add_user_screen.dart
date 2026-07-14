import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
bool canClock = true;

// TF_users.role
String appRole = "employee";

// PP_employee_settings.permission_level
String permissionLevel = "employee";

  Future<void> saveUser() async {
    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        "Veuillez compléter tous les champs obligatoires.",
      );
      return;
    }

    if (!email.contains("@")) {
      _showMessage("Veuillez entrer une adresse email valide.");
      return;
    }

    if (password.length < 6) {
      _showMessage(
        "Le mot de passe doit contenir au moins 6 caractères.",
      );
      return;
    }

    final companyId = await SessionService.getCompanyId();

    if (companyId == null || companyId <= 0) {
      _showMessage("Entreprise introuvable dans la session.");
      return;
    }

    setState(() {
      isLoading = true;
    });

final result = await ManagerService.createEmployee(
  firstname: firstname,
  lastname: lastname,
  email: email,
  password: password,
  role: appRole,
  permissionLevel: permissionLevel,
  canClock: canClock,
);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"] != true) {
      _showMessage(
        result["message"]?.toString() ??
            "Impossible de créer l’utilisateur.",
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text("PointagePro"),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Nouvel utilisateur"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isLoading ? null : saveUser,
          child: const Text(
            "Créer",
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            40,
          ),
          children: [
            const Text(
              "Nouvel utilisateur",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Ajoutez une personne à votre équipe PointagePro.",
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtitle,
              ),
            ),

            const SizedBox(height: 24),

            const _SectionTitle(
              title: "Informations personnelles",
            ),

            IosCard(
              child: Column(
                children: [
                  _CupertinoField(
                    controller: firstnameController,
                    placeholder: "Prénom",
                    icon: CupertinoIcons.person,
                    textCapitalization:
                        TextCapitalization.words,
                  ),
                  const _Divider(),
                  _CupertinoField(
                    controller: lastnameController,
                    placeholder: "Nom",
                    icon: CupertinoIcons.person_crop_circle,
                    textCapitalization:
                        TextCapitalization.words,
                  ),
                  const _Divider(),
                  _CupertinoField(
                    controller: emailController,
                    placeholder: "Adresse email",
                    icon: CupertinoIcons.mail,
                    keyboardType:
                        TextInputType.emailAddress,
                    autocorrect: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const _SectionTitle(
              title: "Mot de passe",
            ),

            IosCard(
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.lock,
                    color: AppColors.subtitle,
                    size: 21,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: CupertinoTextField(
                      controller: passwordController,
                      placeholder: "Mot de passe",
                      obscureText: obscurePassword,
                      autocorrect: false,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      decoration: null,
                    ),
                  ),

                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                    child: Icon(
                      obscurePassword
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: AppColors.subtitle,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

const _SectionTitle(
  title: "Accès à l'application",
),

            IosCard(
              child: CupertinoSlidingSegmentedControl<String>(
  groupValue: appRole,
  children: const {
    "employee": Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text("Employé"),
    ),
    "admin": Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text("Administrateur"),
    ),
  },
  onValueChanged: (value) {
    if (value == null) return;

    setState(() {
      appRole = value;
    });
  },
)
            ),

const SizedBox(height: 22),

const _SectionTitle(
  title: "Fonction dans le magasin",
),

IosCard(
  child: CupertinoSlidingSegmentedControl<String>(
    groupValue: permissionLevel,
    children: const {
      "employee": Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text("Employé"),
      ),
      "student": Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text("Étudiant"),
      ),
      "flexi": Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text("Flexi"),
      ),
      "manager": Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text("Manager"),
      ),
      "admin": Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Text("Admin"),
      ),
    },
    onValueChanged: (value) {
      if (value == null) return;

      setState(() {
        permissionLevel = value;
      });
    },
  ),
),

            const SizedBox(height: 22),

            const _SectionTitle(
              title: "Autorisation",
            ),

            IosCard(
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    color: AppColors.subtitle,
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Autoriser le pointage",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "L’utilisateur pourra scanner le QR code.",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  CupertinoSwitch(
                    value: canClock,
                    onChanged: (value) {
                      setState(() {
                        canClock = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            CupertinoButton.filled(
              onPressed: isLoading ? null : saveUser,
              child: isLoading
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.person_add_solid,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Text(
                          "Créer l’utilisateur",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
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

class _CupertinoField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  const _CupertinoField({
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType,
    this.textCapitalization =
        TextCapitalization.none,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.subtitle,
          size: 21,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            autocorrect: autocorrect,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
            decoration: null,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.subtitle,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 33),
      child: SizedBox(
        height: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.softBorder,
          ),
        ),
      ),
    );
  }
}