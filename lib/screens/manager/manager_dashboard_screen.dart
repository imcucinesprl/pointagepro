import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';
import '../../core/services/manager_service.dart';
import 'employee_day_screen.dart';
import 'dart:async';
import 'manager_employees_screen.dart';
import '../admin/admin_hours_stats_screen.dart';
import '../../core/services/session_service.dart';
import 'manager_planning_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  Timer? _refreshTimer;
  bool isLoading = true;
  String? errorMessage;

  int present = 0;
  int onBreak = 0;
  int finished = 0;
  int notClocked = 0;

  String selectedFilter = 'all';

  List<dynamic> employees = [];

  List<dynamic> get filteredEmployees {
    if (selectedFilter == 'all') return employees;

    return employees.where((employee) {
      return employee["status"]?.toString() == selectedFilter;
    }).toList();
  }

@override
void initState() {
  super.initState();

  loadDashboard();

  _refreshTimer = Timer.periodic(
    const Duration(seconds: 30),
    (_) => loadDashboard(silent: true),
  );
}
@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}

Future<void> loadDashboard({bool silent = false}) async {
  if (!silent) {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
  }

  final result = await ManagerService.today();

  if (!mounted) return;

  if (result["success"] != true) {
    setState(() {
      isLoading = false;
      errorMessage = result["message"]?.toString() ?? "Erreur inconnue";
    });
    return;
  }

  final stats = result["stats"] ?? {};

  setState(() {
    present = stats["present"] ?? 0;
    onBreak = stats["on_break"] ?? 0;
    finished = stats["finished"] ?? 0;
    notClocked = stats["not_clocked"] ?? 0;
    employees = result["employees"] ?? [];
    isLoading = false;
  });
}

  void selectFilter(String filter) {
    setState(() {
      selectedFilter = selectedFilter == filter ? 'all' : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleEmployees = filteredEmployees;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Manager'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: loadDashboard,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 18),

                      const Text(
                        'Présences',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Vue en direct de ton équipe.',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.subtitle,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => selectFilter('present'),
                              child: _StatCard(
                                title: 'Présents',
                                value: present.toString(),
                                color: AppColors.success,
                                icon: CupertinoIcons.check_mark_circled_solid,
                                isSelected: selectedFilter == 'present',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => selectFilter('on_break'),
                              child: _StatCard(
                                title: 'Pause',
                                value: onBreak.toString(),
                                color: AppColors.warning,
                                icon: CupertinoIcons.pause_circle_fill,
                                isSelected: selectedFilter == 'on_break',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => selectFilter('finished'),
                              child: _StatCard(
                                title: 'Terminés',
                                value: finished.toString(),
                                color: AppColors.subtitle,
                                icon: CupertinoIcons.flag_circle_fill,
                                isSelected: selectedFilter == 'finished',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => selectFilter('not_clocked'),
                              child: _StatCard(
                                title: 'Non pointés',
                                value: notClocked.toString(),
                                color: AppColors.danger,
                                icon: CupertinoIcons.clock_fill,
                                isSelected: selectedFilter == 'not_clocked',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (selectedFilter != 'all')
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => selectFilter(selectedFilter),
                          child: const Text(
                            'Afficher toute l’équipe',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),


SizedBox(
  height: 50,
  child: CupertinoButton.filled(
    onPressed: () {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => const ManagerEmployeesScreen(),
        ),
      );
    },
    child: const Text(
      'Gérer les employés',
      style: TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),

const SizedBox(height: 12),

SizedBox(
  height: 50,
  child: CupertinoButton(
    color: CupertinoColors.systemTeal,
    onPressed: () async {

      final companyId = await SessionService.getCompanyId();

      if (!context.mounted || companyId == null) {
        return;
      }

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ManagerPlanningScreen(
            companyId: companyId,
          ),
        ),
      );
    },
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.calendar,
          color: CupertinoColors.white,
        ),
        SizedBox(width: 8),
        Text(
          'Planning',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 12),

SizedBox(
  height: 50,
  child: CupertinoButton(
    color: CupertinoColors.systemIndigo,
    onPressed: () async {

      final companyId = await SessionService.getCompanyId();

      if (!context.mounted || companyId == null) {
        return;
      }

      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => AdminHoursStatsScreen(
            companyId: companyId,
          ),
        ),
      );
    },
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.chart_bar_fill,
          color: CupertinoColors.white,
        ),
        SizedBox(width: 8),
        Text(
          'Statistiques des heures',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 24),


                      Text(
                        selectedFilter == 'all'
                            ? 'Équipe magasin'
                            : 'Filtre : ${_statusLabel(selectedFilter)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),

                      const SizedBox(height: 12),

                      IosCard(
                        child: visibleEmployees.isEmpty
                            ? const Text(
                                'Aucun employé dans ce filtre.',
                                style: TextStyle(
                                  color: AppColors.subtitle,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0;
                                      i < visibleEmployees.length;
                                      i++) ...[
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) => EmployeeDayScreen(
                                              userId: int.tryParse(
                                                    visibleEmployees[i]["id"]
                                                        .toString(),
                                                  ) ??
                                                  0,
                                            ),
                                          ),
                                        );
                                      },
                                      child: _EmployeePresenceRow(
                                        name: visibleEmployees[i]["name"]
                                                ?.toString() ??
                                            "",
                                        detail: visibleEmployees[i]["detail"]
                                                ?.toString() ??
                                            "",
                                        statusLabel: _statusLabel(
                                          visibleEmployees[i]["status"]
                                              ?.toString(),
                                        ),
                                        color: _statusColor(
                                          visibleEmployees[i]["status"]
                                              ?.toString(),
                                        ),
                                        icon: _statusIcon(
                                          visibleEmployees[i]["status"]
                                              ?.toString(),
                                        ),
                                      ),
                                    ),
                                    if (i != visibleEmployees.length - 1)
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

  String _statusLabel(String? status) {
    switch (status) {
      case "present":
        return "Présent";
      case "on_break":
        return "Pause";
      case "finished":
        return "Terminé";
      case "not_clocked":
        return "Non pointé";
      default:
        return "Tous";
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "present":
        return AppColors.success;
      case "on_break":
        return AppColors.warning;
      case "finished":
        return AppColors.subtitle;
      case "not_clocked":
        return AppColors.danger;
      default:
        return AppColors.subtitle;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case "present":
        return CupertinoIcons.check_mark_circled_solid;
      case "on_break":
        return CupertinoIcons.pause_circle_fill;
      case "finished":
        return CupertinoIcons.flag_circle_fill;
      case "not_clocked":
        return CupertinoIcons.clock_fill;
      default:
        return CupertinoIcons.person_2_fill;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSelected;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return IosCard(
      padding: const EdgeInsets.all(18),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : CupertinoColors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeePresenceRow extends StatelessWidget {
  final String name;
  final String detail;
  final String statusLabel;
  final Color color;
  final IconData icon;

  const _EmployeePresenceRow({
    required this.name,
    required this.detail,
    required this.statusLabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? "Employé" : name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
        Text(
          statusLabel,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w800,
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
          decoration: BoxDecoration(color: AppColors.softBorder),
        ),
      ),
    );
  }
}