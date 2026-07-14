import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

class ManagerEmployeesScreen extends StatefulWidget {
  const ManagerEmployeesScreen({super.key});

  @override
  State<ManagerEmployeesScreen> createState() =>
      _ManagerEmployeesScreenState();
}

class _ManagerEmployeesScreenState extends State<ManagerEmployeesScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> employees = [];

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ManagerService.employees();

    if (!mounted) return;

    if (result["success"] != true) {
      setState(() {
        isLoading = false;
        errorMessage =
            result["message"]?.toString() ?? "Erreur inconnue";
      });
      return;
    }

    setState(() {
      employees = result["employees"] ?? [];
      isLoading = false;
    });
  }

  Future<void> openAddUser() async {
    final created = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => const AddUserScreen(),
      ),
    );

    if (created == true) {
      await loadEmployees();
    }
  }

  Future<void> openEditUser(Map<String, dynamic> employee) async {
    final updated = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => EditUserScreen(
          employee: employee,
        ),
      ),
    );

    if (updated == true) {
      await loadEmployees();
    }
  }

  Future<void> showEmployeeActions(
    Map<String, dynamic> employee,
  ) async {
    final employeeId = int.tryParse(
      employee["id"]?.toString() ?? "",
    );

    if (employeeId == null || employeeId <= 0) {
      showMessage(
        "Impossible d’identifier cet utilisateur.",
      );
      return;
    }

    final employeeName = _employeeName(employee);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: Text(employeeName),
          message: Text(
            employee["email"]?.toString() ?? "",
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(popupContext).pop();
                openEditUser(employee);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.pencil,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Text("Modifier l’utilisateur"),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(popupContext).pop();
                confirmDeleteUser(employee);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.delete,
                    size: 20,
                    color: CupertinoColors.destructiveRed,
                  ),
                  SizedBox(width: 9),
                  Text("Supprimer l’utilisateur"),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(popupContext).pop();
            },
            child: const Text("Annuler"),
          ),
        );
      },
    );
  }

  Future<void> confirmDeleteUser(
    Map<String, dynamic> employee,
  ) async {
    final employeeId = int.tryParse(
      employee["id"]?.toString() ?? "",
    );

    if (employeeId == null || employeeId <= 0) {
      showMessage(
        "Impossible d’identifier cet utilisateur.",
      );
      return;
    }

    final employeeName = _employeeName(employee);

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Supprimer l’utilisateur ?"),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              "Voulez-vous vraiment supprimer $employeeName ?\n\n"
              "Cette action est définitive.",
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Annuler"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text("Supprimer"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await deleteUser(employeeId);
  }

  Future<void> deleteUser(int employeeId) async {
    showLoadingDialog();

    final result = await ManagerService.deleteUser(
      userId: employeeId,
    );

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();

    if (result["success"] != true) {
      showMessage(
        result["message"]?.toString() ??
            "Impossible de supprimer l’utilisateur.",
      );
      return;
    }

    showMessage(
      result["message"]?.toString() ??
          "Utilisateur supprimé.",
      title: "Suppression réussie",
    );

    await loadEmployees();
  }

  void showLoadingDialog() {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const CupertinoAlertDialog(
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CupertinoActivityIndicator(),
          ),
        );
      },
    );
  }

  void showMessage(
    String message, {
    String title = "Information",
  }) {
    if (!mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
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

  String _employeeName(Map<String, dynamic> employee) {
    final name = employee["name"]?.toString().trim() ?? "";

    if (name.isNotEmpty) {
      return name;
    }

    final firstname =
        employee["firstname"]?.toString().trim() ?? "";
    final lastname =
        employee["lastname"]?.toString().trim() ?? "";

    final fullName = "$firstname $lastname".trim();

    return fullName.isEmpty
        ? "cet utilisateur"
        : fullName;
  }

  String roleLabel(String role) {
    switch (role) {
      case "platform_admin":
        return "Platform Admin";

      case "super_admin":
        return "Super Admin";

      case "admin":
        return "Admin";

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

  bool _isEnabled(dynamic value) {
    return value == 1 ||
        value == true ||
        value?.toString() == "1";
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Employés"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(36, 36),
              onPressed: loadEmployees,
              child: const Icon(
                CupertinoIcons.refresh,
                size: 21,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: 12),
              minimumSize: const Size(36, 36),
              onPressed: openAddUser,
              child: const Icon(
                CupertinoIcons.person_add_solid,
                size: 22,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(),
              )
            : errorMessage != null
                ? _ErrorState(
                    message: errorMessage!,
                    onRetry: loadEmployees,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      110,
                    ),
                    children: [
                      const Text(
                        "Équipe",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${employees.length} employé(s)",
                        style: const TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 22),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: openAddUser,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.person_add_solid,
                                color: CupertinoColors.white,
                                size: 21,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Ajouter un utilisateur",
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (employees.isEmpty)
                        _EmptyState(
                          onAddUser: openAddUser,
                        )
                      else
                        IosCard(
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < employees.length;
                                i++
                              ) ...[
                                _EmployeeRow(
                                  employee: Map<String, dynamic>.from(
                                    employees[i] as Map,
                                  ),
                                  role: roleLabel(
                                    employees[i]["role"]
                                            ?.toString() ??
                                        "",
                                  ),
                                  active: _isEnabled(
                                    employees[i]["is_active"],
                                  ),
                                  canClock: _isEnabled(
                                    employees[i]["can_clock"],
                                  ),
                                  onPressed: () {
                                    showEmployeeActions(
                                      Map<String, dynamic>.from(
                                        employees[i] as Map,
                                      ),
                                    );
                                  },
                                ),
                                if (i != employees.length - 1)
                                  const _Divider(),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final Map<String, dynamic> employee;
  final String role;
  final bool active;
  final bool canClock;
  final VoidCallback onPressed;

  const _EmployeeRow({
    required this.employee,
    required this.role,
    required this.active,
    required this.canClock,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final name = employee["name"]?.toString().trim() ?? "";
    final firstname =
        employee["firstname"]?.toString().trim() ?? "";
    final lastname =
        employee["lastname"]?.toString().trim() ?? "";

    final fullName = name.isNotEmpty
        ? name
        : "$firstname $lastname".trim();

    final safeName = fullName.isEmpty
        ? "Utilisateur sans nom"
        : fullName;

    final email = employee["email"]?.toString() ?? "";

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(
            active
                ? CupertinoIcons.person_crop_circle_fill
                : CupertinoIcons.person_crop_circle_badge_xmark,
            color: active
                ? AppColors.success
                : AppColors.danger,
            size: 38,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                if (email.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  "$role • "
                  "${canClock ? "Pointage autorisé" : "Pointage interdit"}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.subtitle,
                  ),
                ),
                if (!active) ...[
                  const SizedBox(height: 4),
                  const Text(
                    "Compte désactivé",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            CupertinoIcons.ellipsis_circle,
            color: AppColors.subtitle,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddUser;

  const _EmptyState({
    required this.onAddUser,
  });

  @override
  Widget build(BuildContext context) {
    return IosCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.person_add,
              size: 46,
              color: AppColors.subtitle,
            ),
            const SizedBox(height: 14),
            const Text(
              "Aucun utilisateur",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              "Ajoutez un utilisateur pour commencer à gérer votre équipe.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              onPressed: onAddUser,
              child: const Text(
                "Ajouter un utilisateur",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.danger,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text("Réessayer"),
            ),
          ],
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
      padding: EdgeInsets.symmetric(vertical: 14),
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