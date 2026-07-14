import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EditUserScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EditUserScreen> createState() =>
      _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isActive = true;
  bool canClock = true;

  String selectedRole = "employee";

  int get userId {
    return int.tryParse(
          widget.employee["id"]?.toString() ?? "",
        ) ??
        0;
  }

  @override
  void initState() {
    super.initState();

    firstnameController.text =
        widget.employee["firstname"]?.toString() ?? "";

    lastnameController.text =
        widget.employee["lastname"]?.toString() ?? "";

    emailController.text =
        widget.employee["email"]?.toString() ?? "";

    final role =
        widget.employee["role"]?.toString() ?? "employee";

    selectedRole = availableRoles.contains(role)
        ? role
        : "employee";

    isActive = _isEnabled(
      widget.employee["is_active"],
    );

    canClock = _isEnabled(
      widget.employee["can_clock"],
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

  List<String> get availableRoles {
    return const [
      "employee",
      "student",
      "flexi",
      "manager",
      "admin",
      "super_admin",
    ];
  }

  bool _isEnabled(dynamic value) {
    return value == 1 ||
        value == true ||
        value?.toString() == "1";
  }

  String roleLabel(String role) {
    switch (role) {
      case "super_admin":
        return "Super Admin";

      case "admin":
        return "Administrateur";

      case "manager":
        return "Manager";

      case "student":
        return "Étudiant";

      case "flexi":
        return "Flexi";

      default:
        return "Employé";
    }
  }

  Future<void> selectRole() async {
    int selectedIndex = availableRoles.indexOf(
      selectedRole,
    );

    if (selectedIndex < 0) {
      selectedIndex = 0;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        int temporaryIndex = selectedIndex;

        return Container(
          height: 330,
          color: CupertinoColors.systemBackground.resolveFrom(
            context,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        onPressed: () {
                          Navigator.of(popupContext).pop();
                        },
                        child: const Text("Annuler"),
                      ),
                      const Text(
                        "Rôle",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        onPressed: () {
                          setState(() {
                            selectedRole =
                                availableRoles[temporaryIndex];
                          });

                          Navigator.of(popupContext).pop();
                        },
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 42,
                    scrollController:
                        FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      temporaryIndex = index;
                    },
                    children: [
                      for (final role in availableRoles)
                        Center(
                          child: Text(
                            roleLabel(role),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> saveUser() async {
    if (isLoading) return;

    final firstname = firstnameController.text.trim();
    final lastname = lastnameController.text.trim();
    final email = emailController.text.trim().toLowerCase();

    if (userId <= 0) {
      showMessage(
        "Impossible d’identifier cet utilisateur.",
      );
      return;
    }

    if (firstname.isEmpty) {
      showMessage(
        "Veuillez indiquer le prénom.",
      );
      return;
    }

    if (lastname.isEmpty) {
      showMessage(
        "Veuillez indiquer le nom.",
      );
      return;
    }

    if (email.isEmpty || !email.contains("@")) {
      showMessage(
        "Veuillez indiquer une adresse e-mail valide.",
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

final result = await ManagerService.updateUser(
  userId: userId,
  firstname: firstname,
  lastname: lastname,
  email: email,
  role: selectedRole,
  password: passwordController.text.trim(),
  isActive: isActive,
  canClock: canClock,
);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result["success"] != true) {
      showMessage(
        result["message"]?.toString() ??
            "Impossible de modifier l’utilisateur.",
      );
      return;
    }

    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Utilisateur modifié"),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              result["message"]?.toString() ??
                  "Les modifications ont été enregistrées.",
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  void showMessage(String message) {
    if (!mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Information"),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Modifier l’utilisateur"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isLoading ? null : saveUser,
          child: isLoading
              ? const CupertinoActivityIndicator()
              : const Text(
                  "Enregistrer",
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
            110,
          ),
          children: [
            const Text(
              "Informations",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Modifiez les informations et les autorisations de cet utilisateur.",
              style: TextStyle(
                fontSize: 15,
                color: AppColors.subtitle,
              ),
            ),

            const SizedBox(height: 24),

            IosCard(
              child: Column(
                children: [
                  _TextFieldRow(
                    label: "Prénom",
                    controller: firstnameController,
                    placeholder: "Prénom",
                    textCapitalization:
                        TextCapitalization.words,
                  ),

                  const _FieldDivider(),

                  _TextFieldRow(
                    label: "Nom",
                    controller: lastnameController,
                    placeholder: "Nom",
                    textCapitalization:
                        TextCapitalization.words,
                  ),

                  const _FieldDivider(),

                  _TextFieldRow(
                    label: "E-mail",
                    controller: emailController,
                    placeholder: "adresse@email.com",
                    keyboardType:
                        TextInputType.emailAddress,
                    autocorrect: false,
                  ),

                  const _FieldDivider(),

_TextFieldRow(
  label: "Mot de passe",
  controller: passwordController,
  placeholder: "Laisser vide pour ne pas modifier",
  obscureText: true,
  autocorrect: false,
),

                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              "Rôle et autorisations",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 10),

            IosCard(
              child: Column(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    onPressed: selectRole,
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.person_badge_plus,
                          color: AppColors.text,
                          size: 22,
                        ),

                        const SizedBox(width: 13),

                        const Expanded(
                          child: Text(
                            "Rôle",
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Text(
                          roleLabel(selectedRole),
                          style: const TextStyle(
                            color: AppColors.subtitle,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(width: 6),

                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: AppColors.subtitle,
                          size: 17,
                        ),
                      ],
                    ),
                  ),

                  const _FieldDivider(),

                  _SwitchRow(
                    icon: CupertinoIcons.checkmark_circle,
                    title: "Compte actif",
                    subtitle: isActive
                        ? "L’utilisateur peut se connecter."
                        : "La connexion est désactivée.",
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;

                        if (!value) {
                          canClock = false;
                        }
                      });
                    },
                  ),

                  const _FieldDivider(),

                  _SwitchRow(
                    icon: CupertinoIcons.qrcode_viewfinder,
                    title: "Autoriser le pointage",
                    subtitle: canClock
                        ? "L’utilisateur peut pointer."
                        : "Le pointage est interdit.",
                    value: canClock,
                    onChanged: isActive
                        ? (value) {
                            setState(() {
                              canClock = value;
                            });
                          }
                        : null,
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
                  : const Text(
                      "Enregistrer les modifications",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextFieldRow extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool obscureText;

  const _TextFieldRow({
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              autocorrect: autocorrect,
              enableSuggestions: autocorrect,
              obscureText: obscureText,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.text,
              size: 22,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subtitle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 16),
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