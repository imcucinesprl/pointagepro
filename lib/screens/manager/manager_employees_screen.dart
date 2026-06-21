import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';

class ManagerEmployeesScreen extends StatefulWidget {
  const ManagerEmployeesScreen({super.key});

  @override
  State<ManagerEmployeesScreen> createState() =>
      _ManagerEmployeesScreenState();
}

class _ManagerEmployeesScreenState
    extends State<ManagerEmployeesScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> employees = [];

  @override
  void initState() {
    super.initState();
    loadEmployees();
  }

  Future<void> loadEmployees() async {
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

  String roleLabel(String role) {
    switch (role) {
      case "platform_admin":
        return "Platform Admin";
      case "super_admin":
        return "Super Admin";
      case "admin":
        return "Admin";
      default:
        return "Employé";
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Employés"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: loadEmployees,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(),
              )
            : errorMessage != null
                ? Center(
                    child: Text(errorMessage!),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
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

                      const SizedBox(height: 24),

                      IosCard(
                        child: Column(
                          children: [
                            for (int i = 0;
                                i < employees.length;
                                i++) ...[
                              _EmployeeRow(
                                name: employees[i]["name"] ?? "",
                                email:
                                    employees[i]["email"] ?? "",
                                role: roleLabel(
                                  employees[i]["role"] ?? "",
                                ),
                                active:
                                    employees[i]["is_active"] == 1,
                                canClock:
                                    employees[i]["can_clock"] == 1,
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
  final String name;
  final String email;
  final String role;
  final bool active;
  final bool canClock;

  const _EmployeeRow({
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.canClock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          active
              ? CupertinoIcons.person_crop_circle_fill
              : CupertinoIcons.person_crop_circle_badge_xmark,
          color: active
              ? AppColors.success
              : AppColors.danger,
          size: 34,
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  color: AppColors.subtitle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$role • ${canClock ? "Pointage autorisé" : "Pointage interdit"}",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ],
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