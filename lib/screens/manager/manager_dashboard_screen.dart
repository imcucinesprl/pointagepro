import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';
import '../admin/admin_hours_stats_screen.dart';
import 'employee_day_screen.dart';
import 'manager_employees_screen.dart';
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

  String managerName = '';

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

  int get totalEmployees {
    return present + onBreak + finished + notClocked;
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
      child: SafeArea(
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(radius: 14),
              )
            : errorMessage != null
                ? _ErrorState(
                    message: errorMessage!,
                    onRetry: loadDashboard,
                  )
                : CustomScrollView(
                    slivers: [
                      CupertinoSliverNavigationBar(
                        backgroundColor:
                            AppColors.background.withOpacity(0.92),
                        border: null,
                        largeTitle: const Text('Manager'),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: loadDashboard,
                          child: const Icon(CupertinoIcons.refresh),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              _HeroCard(
  totalEmployees: totalEmployees,
  present: present,
  managerName: managerName,
),
const SizedBox(height: 18),

GestureDetector(
  onTap: () => selectFilter('present'),
  child: _GlassStatCard(
    title: 'Présents',
    value: present.toString(),
    subtitle: totalEmployees > 0
        ? 'Sur $totalEmployees employés'
        : 'Aujourd’hui',
    color: AppColors.success,
    icon: CupertinoIcons.check_mark_circled_solid,
    isSelected: selectedFilter == 'present',
  ),
),

const SizedBox(height: 14),

GestureDetector(
  onTap: () => selectFilter('on_break'),
  child: _GlassStatCard(
    title: 'En pause',
    value: onBreak.toString(),
    subtitle: 'Actuellement',
    color: AppColors.warning,
    icon: CupertinoIcons.pause_fill,
    isSelected: selectedFilter == 'on_break',
  ),
),

const SizedBox(height: 14),

GestureDetector(
  onTap: () => selectFilter('not_clocked'),
  child: _GlassStatCard(
    title: 'Absents / Repos',
    value: notClocked.toString(),
    subtitle: 'Aujourd’hui',
    color: AppColors.danger,
    icon: CupertinoIcons.xmark_circle_fill,
    isSelected: selectedFilter == 'not_clocked',
  ),
),

const SizedBox(height: 14),

GestureDetector(
  onTap: () => selectFilter('finished'),
  child: _GlassStatCard(
    title: 'Terminés',
    value: finished.toString(),
    subtitle: 'Journée finie',
    color: AppColors.subtitle,
    icon: CupertinoIcons.flag_circle_fill,
    isSelected: selectedFilter == 'finished',
  ),
),

const SizedBox(height: 18),

                              if (selectedFilter != 'all')
                                _ClearFilterButton(
                                  label:
                                      'Filtre : ${_statusLabel(selectedFilter)}',
                                  onTap: () => selectFilter(selectedFilter),
                                ),

                              const SizedBox(height: 18),

                              _SectionCard(
                                title: selectedFilter == 'all'
                                    ? 'Équipe magasin'
                                    : 'Équipe filtrée',
                                trailing: '${visibleEmployees.length}',
                                child: visibleEmployees.isEmpty
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          'Aucun employé dans ce filtre.',
                                          style: TextStyle(
                                            color: AppColors.subtitle,
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                                    builder: (_) =>
                                                        EmployeeDayScreen(
                                                      userId: int.tryParse(
                                                            visibleEmployees[i]
                                                                    ["id"]
                                                                .toString(),
                                                          ) ??
                                                          0,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _EmployeePresenceRow(
                                                name: visibleEmployees[i]
                                                            ["name"]
                                                        ?.toString() ??
                                                    "",
                                                detail: visibleEmployees[i]
                                                            ["detail"]
                                                        ?.toString() ??
                                                    "",
                                                statusLabel: _statusLabel(
                                                  visibleEmployees[i]
                                                          ["status"]
                                                      ?.toString(),
                                                ),
                                                color: _statusColor(
                                                  visibleEmployees[i]
                                                          ["status"]
                                                      ?.toString(),
                                                ),
                                                icon: _statusIcon(
                                                  visibleEmployees[i]
                                                          ["status"]
                                                      ?.toString(),
                                                ),
                                              ),
                                            ),
                                            if (i !=
                                                visibleEmployees.length - 1)
                                              const _SoftDivider(),
                                          ],
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 18),

                              _SectionCard(
                                title: 'Actions rapides',
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _QuickAction(
                                      label: 'Employés',
                                      icon: CupertinoIcons.person_2_fill,
                                      color: CupertinoColors.systemIndigo,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) =>
                                                const ManagerEmployeesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickAction(
                                      label: 'Planning',
                                      icon: CupertinoIcons.calendar,
                                      color: CupertinoColors.systemTeal,
                                      onTap: () async {
                                        final companyId =
                                            await SessionService.getCompanyId();

                                        if (!context.mounted ||
                                            companyId == null) {
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) =>
                                                ManagerPlanningScreen(
                                              companyId: companyId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickAction(
                                      label: 'Rapports',
                                      icon: CupertinoIcons.chart_bar_fill,
                                      color: CupertinoColors.systemPurple,
                                      onTap: () async {
                                        final companyId =
                                            await SessionService.getCompanyId();

                                        if (!context.mounted ||
                                            companyId == null) {
                                          return;
                                        }

                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (_) =>
                                                AdminHoursStatsScreen(
                                              companyId: companyId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  int _percent(int value) {
    if (totalEmployees <= 0) return 0;
    return ((value / totalEmployees) * 100).round();
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

class _HeroCard extends StatelessWidget {
  final int totalEmployees;
  final int present;
  final String managerName;

  const _HeroCard({
    required this.totalEmployees,
    required this.present,
    required this.managerName,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

return Container(
  constraints: const BoxConstraints(
    minHeight: 190,
  ),
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(32),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4C8DFF),
        Color(0xFF7B61FF),
        Color(0xFFB95CFF),
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF6D5BFF).withOpacity(0.28),
        blurRadius: 26,
        offset: const Offset(0, 16),
      ),
    ],
  ),
  child: Stack(
    children: [
      Positioned(
        right: -40,
        top: -30,
        child: _BlurCircle(size: 180, opacity: 0.16),
      ),
      Positioned(
        right: 18,
        bottom: 14,
        child: _HeroMiniGlassCard(
          present: present,
          totalEmployees: totalEmployees,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.person_2_fill,
              color: CupertinoColors.white,
              size: 25,
            ),
          ),
          const SizedBox(height: 14),
Text(
  managerName.isEmpty
      ? 'Bienvenue'
      : 'Bienvenue $managerName',
  style: const TextStyle(
    color: CupertinoColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),
          const SizedBox(height: 6),
          const Text(
            'Vue d’ensemble\nde votre équipe',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 29,
              height: 1.06,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                color: CupertinoColors.white,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                _formattedDate(now),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
  }

  static String _formattedDate(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _HeroMiniGlassCard extends StatelessWidget {
  final int present;
  final int totalEmployees;

  const _HeroMiniGlassCard({
    required this.present,
    required this.totalEmployees,
  });

  @override
  Widget build(BuildContext context) {
    final percent =
        totalEmployees <= 0 ? 0 : ((present / totalEmployees) * 100).round();

    return Container(
      width: 108,
      height: 104,
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CupertinoColors.white.withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Icon(
      CupertinoIcons.person_2_fill,
      color: CupertinoColors.white,
      size: 30,
    ),
    const SizedBox(height: 8),
    Text(
      '$present',
      style: const TextStyle(
        color: CupertinoColors.white,
        fontSize: 34,
        fontWeight: FontWeight.w900,
      ),
    ),
    Text(
      'sur $totalEmployees',
      style: TextStyle(
        color: CupertinoColors.white.withOpacity(0.9),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],
),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _BlurCircle({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CupertinoColors.white.withOpacity(opacity),
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  final Color color;
  final IconData icon;
  final bool isSelected;

  const _GlassStatCard({
    required this.title,
    required this.value,
    required this.subtitle,

    required this.color,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
return AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  padding: const EdgeInsets.all(18),
  constraints: const BoxConstraints(
    minHeight: 142,
  ),
  decoration: BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: isSelected ? color.withOpacity(0.55) : CupertinoColors.white,
      width: isSelected ? 1.6 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(isSelected ? 0.18 : 0.08),
        blurRadius: isSelected ? 24 : 18,
        offset: const Offset(0, 10),
      ),
    ],
  ),
      child: Row(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              icon,
              color: color,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),

          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
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
    final displayName = name.isEmpty ? "Employé" : name;

    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail.isEmpty ? 'Aucun détail' : detail,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          CupertinoIcons.chevron_right,
          color: AppColors.subtitle,
          size: 18,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        children: [
          Container(
            height: 74,
            width: 74,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ClearFilterButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 18,
              color: AppColors.primary,
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
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              color: AppColors.danger,
              size: 42,
            ),
            const SizedBox(height: 14),
            const Text(
              'Erreur',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.subtitle,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(
        height: 1,
        color: AppColors.softBorder.withOpacity(0.75),
      ),
    );
  }
}