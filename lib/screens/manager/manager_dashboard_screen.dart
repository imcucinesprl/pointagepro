import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

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
  State<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  Timer? _refreshTimer;

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;
  DateTime? lastUpdatedAt;

  String managerName = '';
  String selectedFilter = 'all';

  int present = 0;
  int onBreak = 0;
  int finished = 0;
  int notClocked = 0;
  int scheduledToday = 0;
  int expectedNow = 0;
  int activeExpectedNow = 0;
  int late = 0;
  int absent = 0;
  int unexpected = 0;
  int longBreaks = 0;

  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> planning = [];
  List<Map<String, dynamic>> alerts = [];
  List<Map<String, dynamic>> recentActivity = [];

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

  static const String _baseUrl = 'https://taskflowapp.eu/pointagepro';

  DateTime _startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );
  }

  String _dateToApiString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> _loadPlanningWeek(int companyId) async {
    final weekStart = _dateToApiString(_startOfWeek(DateTime.now()));
    final uri = Uri.parse(
      '$_baseUrl/planning_comparison.php'
      '?company_id=$companyId'
      '&week_start=$weekStart',
    );

    try {
      final response = await http.get(uri);
      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        return {
          'success': false,
          'message': 'Réponse planning invalide.',
        };
      }

      final data = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      if (response.statusCode != 200 || data['success'] != true) {
        return {
          'success': false,
          'message': data['message']?.toString() ??
              'Impossible de charger le planning.',
        };
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au planning : $e',
      };
    }
  }

  Map<String, dynamic>? _todayPlanningDay(
    Map<String, dynamic> planningResult,
  ) {
    final today = _dateToApiString(DateTime.now());
    final days = _asMapList(planningResult['days']);

    for (final day in days) {
      if (day['date']?.toString() == today) {
        return day;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _mergePlanningAndPointages({
    required List<Map<String, dynamic>> plannedEmployees,
    required List<Map<String, dynamic>> liveEmployees,
  }) {
    final liveByUserId = <int, Map<String, dynamic>>{};

    for (final employee in liveEmployees) {
      final userId = _toInt(
        employee['user_id'] ?? employee['employee_id'] ?? employee['id'],
      );

      if (userId > 0) {
        liveByUserId[userId] = employee;
      }
    }

    final merged = <Map<String, dynamic>>[];

    for (final plannedEmployee in plannedEmployees) {
      if (!_hasWorkingSchedule(plannedEmployee)) continue;

      final userId = _toInt(
        plannedEmployee['user_id'] ??
            plannedEmployee['employee_id'] ??
            plannedEmployee['id'],
      );

      if (userId <= 0) continue;

      final liveEmployee = liveByUserId[userId];
      final fullName = plannedEmployee['full_name']?.toString().trim() ?? '';

      merged.add({
        ...plannedEmployee,
        if (liveEmployee != null) ...liveEmployee,
        'id': userId,
        'user_id': userId,
        'name': liveEmployee?['name']?.toString().trim().isNotEmpty == true
            ? liveEmployee!['name']
            : fullName,
        'planned_start': plannedEmployee['planned_start'] ??
            plannedEmployee['start_time'] ??
            plannedEmployee['schedule_start'],
        'planned_end': plannedEmployee['planned_end'] ??
            plannedEmployee['end_time'] ??
            plannedEmployee['schedule_end'],
        'planned_status': plannedEmployee['planned_status'] ??
            plannedEmployee['planning_status'] ??
            plannedEmployee['status_planning'],
        'status': liveEmployee?['status'] ?? 'not_clocked',
        'detail': liveEmployee?['detail'] ??
            'Prévu ${_plannedRange(plannedEmployee)}',
      });
    }

    return merged;
  }

  int _countEmployeeStatus(
    List<Map<String, dynamic>> items,
    String status,
  ) {
    return items.where((item) => item['status']?.toString() == status).length;
  }

int? _planningTimeToMinutes(dynamic value) {
  final raw = value?.toString().trim() ?? '';

  if (raw.isEmpty) return null;

  // Format complet : 2026-07-17 08:00:00
  // ou : 2026-07-17T08:00:00
  final dateTimeMatch = RegExp(
    r'(?:T|\s)(\d{1,2}):(\d{2})',
  ).firstMatch(raw);

  if (dateTimeMatch != null) {
    final hour = int.tryParse(dateTimeMatch.group(1)!);
    final minute = int.tryParse(dateTimeMatch.group(2)!);

    if (hour == null || minute == null) return null;

    return (hour * 60) + minute;
  }

  // Format simple : 08:00 ou 08:00:00
  final timeMatch = RegExp(
    r'^(\d{1,2}):(\d{2})',
  ).firstMatch(raw);

  if (timeMatch == null) return null;

  final hour = int.tryParse(timeMatch.group(1)!);
  final minute = int.tryParse(timeMatch.group(2)!);

  if (hour == null || minute == null) return null;

  return (hour * 60) + minute;
}

bool _shouldBeWorkingNow(
  Map<String, dynamic> employee,
  int nowMinutes,
) {
  final plannedStart = _planningTimeToMinutes(
    employee['planned_start'] ??
        employee['start_time'] ??
        employee['schedule_start'],
  );

  final plannedEnd = _planningTimeToMinutes(
    employee['planned_end'] ??
        employee['end_time'] ??
        employee['schedule_end'],
  );

  if (plannedStart == null || plannedEnd == null) {
    return false;
  }

  // Horaire normal, par exemple 06:00–12:00.
  if (plannedEnd > plannedStart) {
    return nowMinutes >= plannedStart &&
        nowMinutes < plannedEnd;
  }

  // Horaire qui passe après minuit, par exemple 22:00–06:00.
  if (plannedEnd < plannedStart) {
    return nowMinutes >= plannedStart ||
        nowMinutes < plannedEnd;
  }

  return false;
}

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    } else if (!isRefreshing) {
      setState(() => isRefreshing = true);
    }

    final companyId = await SessionService.getCompanyId();

    if (!mounted) return;

    if (companyId == null || companyId <= 0) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = 'Entreprise introuvable dans la session.';
      });
      return;
    }

    final results = await Future.wait<Map<String, dynamic>>([
      ManagerService.today(),
      _loadPlanningWeek(companyId),
    ]);

    if (!mounted) return;

    final result = results[0];
    final planningResult = results[1];

    if (result['success'] != true) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = result['message']?.toString() ??
            'Impossible de charger le tableau de bord.';
      });
      return;
    }

    if (planningResult['success'] != true) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = planningResult['message']?.toString() ??
            'Impossible de charger le planning du jour.';
      });
      return;
    }

    final summary = _asMap(result['summary']);
    final stats = _asMap(result['stats']);
    final liveEmployees = _asMapList(result['employees']);
    final todayDay = _todayPlanningDay(planningResult);
    final plannedEmployees = _asMapList(todayDay?['employees']);
    final mergedEmployees = _mergePlanningAndPointages(
      plannedEmployees: plannedEmployees,
      liveEmployees: liveEmployees,
    );

final now = DateTime.now();
final nowMinutes = (now.hour * 60) + now.minute;

final employeesExpectedNow = mergedEmployees.where((employee) {
  return _shouldBeWorkingNow(
    employee,
    nowMinutes,
  );
}).toList();

final loadedExpectedNow = employeesExpectedNow.length;

final loadedActiveExpectedNow = employeesExpectedNow.where((employee) {
  final status = employee['status']
      ?.toString()
      .trim()
      .toLowerCase();

  return status == 'present' ||
      status == 'on_break';
}).length;

    final loadedPresent = _countEmployeeStatus(mergedEmployees, 'present');
    final loadedOnBreak = _countEmployeeStatus(mergedEmployees, 'on_break');
    final loadedFinished = _countEmployeeStatus(mergedEmployees, 'finished');
final loadedNotClocked =
    _countEmployeeStatus(mergedEmployees, 'not_clocked');

final loadedLate = mergedEmployees.where((employee) {
  return _isEmployeeLate(
    employee,
    graceMinutes: 10,
  );
}).length;

final loadedAbsent = mergedEmployees.where((employee) {
  return _isEmployeeAbsent(
    employee,
    absenceAfterMinutes: 60,
  );
}).length;

    final loadedUnexpected = _firstPositiveInt([
      summary['unexpected'],
      stats['unexpected'],
    ]);

    final loadedLongBreaks = _firstPositiveInt([
      summary['long_breaks'],
      stats['long_breaks'],
    ]);

    setState(() {
      present = loadedPresent;
      onBreak = loadedOnBreak;
      finished = loadedFinished;
      notClocked = loadedNotClocked;
      scheduledToday = mergedEmployees.length;
      expectedNow = loadedExpectedNow;
      activeExpectedNow = loadedActiveExpectedNow;
      late = loadedLate;
      absent = loadedAbsent;
      unexpected = loadedUnexpected;
      longBreaks = loadedLongBreaks;

      employees = mergedEmployees;
      planning = mergedEmployees;
      alerts = _asMapList(result['alerts']);
      recentActivity = _asMapList(
        result['recent_activity'] ?? result['timeline'] ?? result['activity'],
      );

      lastUpdatedAt = DateTime.now();
      isLoading = false;
      isRefreshing = false;
      errorMessage = null;
    });
  }

  List<Map<String, dynamic>> get todayScheduledEmployees => employees;

  List<Map<String, dynamic>> get filteredEmployees {
    final source = todayScheduledEmployees;

    if (selectedFilter == 'all') return source;

    return source.where((employee) {
      return employee['status']?.toString() == selectedFilter;
    }).toList();
  }

  int get activeNow => present + onBreak;

  int get totalEmployees => present + onBreak + finished + notClocked;

int get presencePercent {
  if (expectedNow <= 0) {
    return 0;
  }

  return ((activeExpectedNow / expectedNow) * 100)
      .clamp(0, 100)
      .round();
}

  int get anomalyCount {
    if (alerts.isNotEmpty) return alerts.length;
    return late + absent + unexpected + longBreaks;
  }

  _StoreHealth get storeHealth {
    if (absent >= 2 || anomalyCount >= 4) {
      return const _StoreHealth(
        label: 'Attention nécessaire',
        message: 'Plusieurs anomalies doivent être vérifiées.',
        color: AppColors.danger,
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      );
    }

    if (anomalyCount > 0) {
      return const _StoreHealth(
        label: 'Quelques anomalies',
        message: 'La journée est sous contrôle, mais certains points sont à vérifier.',
        color: AppColors.warning,
        icon: CupertinoIcons.exclamationmark_circle_fill,
      );
    }

    return const _StoreHealth(
      label: 'Tout est normal',
      message: 'Aucune anomalie détectée pour le moment.',
      color: AppColors.success,
      icon: CupertinoIcons.check_mark_circled_solid,
    );
  }

  void selectFilter(String filter) {
    setState(() {
      selectedFilter = selectedFilter == filter ? 'all' : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlanning = filteredEmployees;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : errorMessage != null
                ? _ErrorState(message: errorMessage!, onRetry: loadDashboard)
                : CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      CupertinoSliverNavigationBar(
                        backgroundColor: AppColors.background.withOpacity(0.94),
                        border: null,
                        largeTitle: const Text('Manager'),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: isRefreshing
                              ? null
                              : () => loadDashboard(silent: true),
                          child: isRefreshing
                              ? const CupertinoActivityIndicator(radius: 10)
                              : const Icon(CupertinoIcons.refresh),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
_DashboardHero(
  managerName: managerName,
  scheduledToday: scheduledToday,
  activeNow: activeNow,
  expectedNow: expectedNow,
  activeExpectedNow: activeExpectedNow,
  absent: absent,
  presencePercent: presencePercent,
  anomalyCount: anomalyCount,
  lastUpdatedAt: lastUpdatedAt,
),
                            const SizedBox(height: 16),
                            _HealthCard(health: storeHealth),
                            const SizedBox(height: 16),
                            _StatsGrid(
                              present: present,
                              onBreak: onBreak,
                              finished: finished,
                              absent: absent > 0 ? absent : notClocked,
                              selectedFilter: selectedFilter,
                              onSelected: selectFilter,
                            ),
                            if (selectedFilter != 'all') ...[
                              const SizedBox(height: 12),
                              _ClearFilterButton(
                                label: 'Filtre : ${_statusLabel(selectedFilter)}',
                                onTap: () => selectFilter(selectedFilter),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _PlanningRealityCard(
                              scheduledToday: scheduledToday,
                              activeNow: activeNow,
                              late: late,
                              absent: absent,
                              unexpected: unexpected,
                              planning: visiblePlanning,
                              selectedFilter: selectedFilter,
                              onEmployeeTap: _openEmployee,
                              onPlanningTap: _openPlanning,
                            ),
                            const SizedBox(height: 16),
                            _AlertsCard(
                              alerts: alerts,
                              fallbackAlerts: _buildFallbackAlerts(),
                              onEmployeeTap: _openEmployee,
                            ),
                            const SizedBox(height: 16),
                            _ActivityCard(activity: recentActivity),
                            const SizedBox(height: 16),
                            _QuickActionsCard(
                              onEmployeesTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) =>
                                        const ManagerEmployeesScreen(),
                                  ),
                                );
                              },
                              onPlanningTap: _openPlanning,
                              onReportsTap: _openReports,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildFallbackAlerts() {
    final items = <Map<String, dynamic>>[];

    if (absent > 0) {
      items.add({
        'type': 'absent',
        'title': '$absent employé${absent > 1 ? 's' : ''} attendu${absent > 1 ? 's' : ''}',
        'detail': 'Prévu${absent > 1 ? 's' : ''} aujourd’hui mais pas encore présent${absent > 1 ? 's' : ''}.',
      });
    }

    if (late > 0) {
      items.add({
        'type': 'late',
        'title': '$late retard${late > 1 ? 's' : ''}',
        'detail': 'Vérifie les arrivées prévues et les heures réelles.',
      });
    }

    if (longBreaks > 0) {
      items.add({
        'type': 'long_break',
        'title': '$longBreaks pause${longBreaks > 1 ? 's' : ''} longue${longBreaks > 1 ? 's' : ''}',
        'detail': 'Une pause dépasse la durée habituelle.',
      });
    }

    if (unexpected > 0) {
      items.add({
        'type': 'unexpected',
        'title': '$unexpected présence${unexpected > 1 ? 's' : ''} non prévue${unexpected > 1 ? 's' : ''}',
        'detail': 'Présent au pointage mais absent du planning.',
      });
    }

    return items;
  }

  Future<void> _openPlanning() async {
    final companyId = await SessionService.getCompanyId();
    if (!mounted || companyId == null) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ManagerPlanningScreen(companyId: companyId),
      ),
    );
  }

  Future<void> _openReports() async {
    final companyId = await SessionService.getCompanyId();
    if (!mounted || companyId == null) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => AdminHoursStatsScreen(companyId: companyId),
      ),
    );
  }

  void _openEmployee(int userId) {
    if (userId <= 0) return;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => EmployeeDayScreen(userId: userId),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String managerName;
  final int scheduledToday;
  final int activeNow;
  final int absent;
  final int presencePercent;
  final int anomalyCount;
  final DateTime? lastUpdatedAt;
  final int expectedNow;
  final int activeExpectedNow;

  const _DashboardHero({
    required this.managerName,
    required this.scheduledToday,
    required this.activeNow,
    required this.absent,
    required this.presencePercent,
    required this.anomalyCount,
    required this.lastUpdatedAt,
    required this.expectedNow,
    required this.activeExpectedNow,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3979F6),
            Color(0xFF6C63F6),
            Color(0xFFA755EC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF665DF2).withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      managerName.isEmpty
                          ? 'Bonjour 👋'
                          : 'Bonjour $managerName 👋',
                      style: TextStyle(
                        color: CupertinoColors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Votre équipe\naujourd’hui',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 29,
                        height: 1.03,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 98,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: CupertinoColors.white.withOpacity(0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$presencePercent%',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'présence',
                      style: TextStyle(
                        color: CupertinoColors.white.withOpacity(0.86),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroValue(
                  value: scheduledToday > 0 ? '$scheduledToday' : '—',
                  label: 'Prévus',
                ),
              ),
              Expanded(
                child: _HeroValue(value: '$activeNow', label: 'Sur place'),
              ),
              Expanded(
                child: _HeroValue(value: '$absent', label: 'Absents'),
              ),
              Expanded(
                child: _HeroValue(value: '$anomalyCount', label: 'Alertes'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoColors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formattedDate(now),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  lastUpdatedAt == null
                      ? ''
                      : 'MAJ ${_hhmm(lastUpdatedAt!)}',
                  style: TextStyle(
                    color: CupertinoColors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  final String value;
  final String label;

  const _HeroValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.78),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final _StoreHealth health;

  const _HealthCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: health.color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: health.color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: health.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(health.icon, color: health.color, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  health.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  health.message,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int present;
  final int onBreak;
  final int finished;
  final int absent;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const _StatsGrid({
    required this.present,
    required this.onBreak,
    required this.finished,
    required this.absent,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _CompactStatCard(
                title: 'Présents',
                value: present,
                filter: 'present',
                color: AppColors.success,
                icon: CupertinoIcons.check_mark_circled_solid,
                selected: selectedFilter == 'present',
                onTap: onSelected,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactStatCard(
                title: 'En pause',
                value: onBreak,
                filter: 'on_break',
                color: AppColors.warning,
                icon: CupertinoIcons.pause_circle_fill,
                selected: selectedFilter == 'on_break',
                onTap: onSelected,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _CompactStatCard(
                title: 'Terminés',
                value: finished,
                filter: 'finished',
                color: AppColors.subtitle,
                icon: CupertinoIcons.flag_circle_fill,
                selected: selectedFilter == 'finished',
                onTap: onSelected,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactStatCard(
                title: 'Non pointés',
                value: absent,
                filter: 'not_clocked',
                color: AppColors.danger,
                icon: CupertinoIcons.person_crop_circle_badge_exclam,
                selected: selectedFilter == 'not_clocked',
                onTap: onSelected,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String title;
  final int value;
  final String filter;
  final Color color;
  final IconData icon;
  final bool selected;
  final ValueChanged<String> onTap;

  const _CompactStatCard({
    required this.title,
    required this.value,
    required this.filter,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: selected ? color.withOpacity(0.55) : CupertinoColors.white,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(selected ? 0.14 : 0.06),
              blurRadius: selected ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.11),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: color,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

class _PlanningRealityCard extends StatelessWidget {
  final int scheduledToday;
  final int activeNow;
  final int late;
  final int absent;
  final int unexpected;
  final List<Map<String, dynamic>> planning;
  final String selectedFilter;
  final ValueChanged<int> onEmployeeTap;
  final VoidCallback onPlanningTap;

  const _PlanningRealityCard({
    required this.scheduledToday,
    required this.activeNow,
    required this.late,
    required this.absent,
    required this.unexpected,
    required this.planning,
    required this.selectedFilter,
    required this.onEmployeeTap,
    required this.onPlanningTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedFilter != 'all';

    return _SectionCard(
      title: isFiltered
          ? 'Planning vs réalité · ${_statusLabel(selectedFilter)}'
          : 'Planning vs réalité',
      trailing: isFiltered
          ? '${planning.length}'
          : scheduledToday > 0
              ? '$activeNow / $scheduledToday'
              : null,
      actionLabel: 'Planning',
      onAction: onPlanningTap,
      child: planning.isEmpty
          ? _EmptyMessage(
              text: isFiltered
                  ? 'Aucun employé ne correspond au filtre « ${_statusLabel(selectedFilter)} ».'
                  : 'Aucun employé n’est planifié aujourd’hui.',
            )
          : Column(
              children: [
                for (int i = 0; i < planning.length; i++) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onEmployeeTap(
                      _toInt(
                        planning[i]['user_id'] ?? planning[i]['id'],
                      ),
                    ),
                    child: _PlanningRealityRow(item: planning[i]),
                  ),
                  if (i != planning.length - 1)
                    const _SoftDivider(),
                ],
              ],
            ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ComparisonMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.subtitle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningRealityRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _PlanningRealityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = (item['comparison_status'] ?? item['status'] ?? '')
        .toString()
        .toLowerCase();
    final color = _comparisonColor(status);
    final icon = _comparisonIcon(status);
    final name = _employeeName(item);
    final planned = _plannedRange(item);
    final detail = _comparisonDetail(item, status);

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                planned.isEmpty ? detail : '$planned · $detail',
                style: const TextStyle(
                  color: AppColors.subtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _comparisonLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> fallbackAlerts;
  final ValueChanged<int> onEmployeeTap;

  const _AlertsCard({
    required this.alerts,
    required this.fallbackAlerts,
    required this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = alerts.isNotEmpty ? alerts : fallbackAlerts;

    return _SectionCard(
      title: 'Besoin d’attention',
      trailing: '${items.length}',
      child: items.isEmpty
          ? const _EmptyMessage(
              icon: CupertinoIcons.check_mark_circled_solid,
              iconColor: AppColors.success,
              text: 'Aucune alerte pour le moment.',
            )
          : Column(
              children: [
                for (int i = 0; i < items.length && i < 5; i++) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onEmployeeTap(
                      _toInt(items[i]['user_id'] ?? items[i]['id']),
                    ),
                    child: _AlertRow(item: items[i]),
                  ),
                  if (i != items.length - 1 && i != 4)
                    const _SoftDivider(),
                ],
              ],
            ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _AlertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] ?? item['status'] ?? 'warning').toString();
    final color = _alertColor(type);
    final title = item['title']?.toString() ?? _employeeName(item);
    final detail = item['detail']?.toString() ??
        item['message']?.toString() ??
        'À vérifier';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(_alertIcon(type), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.subtitle,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmployeePresenceRow extends StatelessWidget {
  final Map<String, dynamic> employee;

  const _EmployeePresenceRow({required this.employee});

  @override
  Widget build(BuildContext context) {
    final status = employee['status']?.toString();
    final color = _statusColor(status);
    final name = _employeeName(employee);
    final detail = _employeeDetail(employee, status);

    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(_statusIcon(status), color: color, size: 24),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.subtitle,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(
          CupertinoIcons.chevron_right,
          color: AppColors.subtitle,
          size: 16,
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Activité récente',
      child: activity.isEmpty
          ? const _EmptyMessage(
              text:
                  'L’activité récente apparaîtra ici dès que l’API renverra la timeline.',
            )
          : Column(
              children: [
                for (int i = 0; i < activity.length && i < 6; i++) ...[
                  _ActivityRow(item: activity[i]),
                  if (i != activity.length - 1 && i != 5)
                    const _SoftDivider(),
                ],
              ],
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] ?? item['event_type'] ?? '').toString();
    final color = _statusColor(_eventToStatus(type));
    final time = _formatApiTime(
      item['time'] ?? item['created_at'] ?? item['timestamp'],
    );
    final text = item['text']?.toString() ??
        item['message']?.toString() ??
        '${_employeeName(item)} · ${_eventLabel(type)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            time,
            style: const TextStyle(
              color: AppColors.subtitle,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback onEmployeesTap;
  final VoidCallback onPlanningTap;
  final VoidCallback onReportsTap;

  const _QuickActionsCard({
    required this.onEmployeesTap,
    required this.onPlanningTap,
    required this.onReportsTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Actions rapides',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickAction(
            label: 'Employés',
            icon: CupertinoIcons.person_2_fill,
            color: CupertinoColors.systemIndigo,
            onTap: onEmployeesTap,
          ),
          _QuickAction(
            label: 'Planning',
            icon: CupertinoIcons.calendar,
            color: CupertinoColors.systemTeal,
            onTap: onPlanningTap,
          ),
          _QuickAction(
            label: 'Rapports',
            icon: CupertinoIcons.chart_bar_fill,
            color: CupertinoColors.systemPurple,
            onTap: onReportsTap,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.045),
            blurRadius: 22,
            offset: const Offset(0, 11),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minSize: 30,
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
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
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
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

  const _ClearFilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
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
              const SizedBox(width: 7),
              const Icon(
                CupertinoIcons.xmark_circle_fill,
                size: 17,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color iconColor;

  const _EmptyMessage({
    required this.text,
    this.icon = CupertinoIcons.info_circle_fill,
    this.iconColor = AppColors.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.subtitle,
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              color: AppColors.danger,
              size: 42,
            ),
            const SizedBox(height: 13),
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
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Container(
        height: 1,
        color: AppColors.softBorder.withOpacity(0.75),
      ),
    );
  }
}

class _StoreHealth {
  final String label;
  final String message;
  final Color color;
  final IconData icon;

  const _StoreHealth({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.map(_asMap).where((item) => item.isNotEmpty).toList();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _firstPositiveInt(List<dynamic> values) {
  for (final value in values) {
    final parsed = _toInt(value);
    if (parsed > 0) return parsed;
  }
  return 0;
}

int _countPlanningStatus(
  List<Map<String, dynamic>> planning,
  Set<String> statuses,
) {
  return planning.where((item) {
    final status = (item['comparison_status'] ?? item['status'] ?? '')
        .toString()
        .toLowerCase();
    return statuses.contains(status);
  }).length;
}


String _normalizePlanningStatus(dynamic value) {
  return (value?.toString() ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('-', '_')
      .replaceAll(' ', '_');
}

String _planningStatusOf(Map<String, dynamic> item) {
  final candidates = [
    item['planned_status'],
    item['planning_status'],
    item['schedule_status'],
    item['day_status'],
    item['status_planning'],
    item['planning_type'],
    item['shift_status'],
  ];

  for (final candidate in candidates) {
    final normalized = _normalizePlanningStatus(candidate);

    if (normalized.isNotEmpty) {
      return normalized;
    }
  }

  return '';
}

bool _hasWorkingSchedule(Map<String, dynamic> item) {
  final planningStatus = _planningStatusOf(item);

  const nonWorkingStatuses = {
    'repos',
    'rest',
    'off',
    'conge',
    'conges',
    'conge_paye',
    'conges_payes',
    'malade',
    'maladie',
    'jf',
    'jour_ferie',
    'vacance',
    'vacances',
    'recup',
    'recuperation',
    'absence',
    'absent',
    'indisponible',
  };

  if (nonWorkingStatuses.contains(planningStatus)) {
    return false;
  }

  const nonWorkingWords = [
    'vacance',
    'conge',
    'malad',
    'ferie',
    'repos',
    'recup',
    'absence',
  ];

  if (nonWorkingWords.any(planningStatus.contains)) {
    return false;
  }

  final start = (
    item['planned_start'] ??
    item['start_time'] ??
    item['schedule_start'] ??
    ''
  ).toString().trim();

  final end = (
    item['planned_end'] ??
    item['end_time'] ??
    item['schedule_end'] ??
    ''
  ).toString().trim();

  return start.isNotEmpty && end.isNotEmpty;
}

String _employeeName(Map<String, dynamic> item) {
  final direct = item['name']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final first = (item['firstname'] ?? item['first_name'] ?? '')
      .toString()
      .trim();
  final last = (item['lastname'] ?? item['last_name'] ?? '')
      .toString()
      .trim();
  final full = '$first $last'.trim();
  return full.isEmpty ? 'Employé' : full;
}

String _employeeDetail(Map<String, dynamic> employee, String? status) {
  final direct = employee['detail']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final arrival = _formatApiTime(
    employee['clock_in'] ?? employee['arrival'] ?? employee['started_at'],
  );
  final worked = employee['worked_formatted']?.toString() ??
      employee['worked_duration']?.toString() ??
      employee['worked_time']?.toString();
  final breakDuration = employee['break_duration']?.toString() ??
      employee['pause_duration']?.toString();

  switch (status) {
    case 'present':
      if (worked != null && worked.isNotEmpty) {
        return 'Arrivé $arrival · $worked travaillées';
      }
      return arrival.isEmpty ? 'Présent actuellement' : 'Arrivé à $arrival';
    case 'on_break':
      return breakDuration == null || breakDuration.isEmpty
          ? 'En pause actuellement'
          : 'En pause depuis $breakDuration';
    case 'finished':
      return worked == null || worked.isEmpty
          ? 'Journée terminée'
          : 'Journée terminée · $worked';
    case 'not_clocked':
      final planned = _plannedRange(employee);
      return planned.isEmpty ? 'Aucun pointage aujourd’hui' : 'Prévu $planned';
    default:
      return 'Aucun détail disponible';
  }
}

String _plannedRange(Map<String, dynamic> item) {
  final direct = item['planned_range']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final start = _formatApiTime(
    item['planned_start'] ?? item['start_time'] ?? item['schedule_start'],
  );
  final end = _formatApiTime(
    item['planned_end'] ?? item['end_time'] ?? item['schedule_end'],
  );

  if (start.isEmpty && end.isEmpty) return '';
  if (end.isEmpty) return 'Prévu $start';
  return '$start–$end';
}

String _comparisonDetail(Map<String, dynamic> item, String status) {
  final direct = item['detail']?.toString().trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final delay = _toInt(item['delay_minutes'] ?? item['late_minutes']);
  switch (status) {
    case 'late':
      return delay > 0 ? 'Arrivée avec $delay min de retard' : 'Arrivé en retard';
    case 'absent':
    case 'missing':
      return 'Toujours absent';
    case 'unexpected':
    case 'not_planned':
      return 'Présent mais non prévu';
    case 'on_break':
      return 'En pause actuellement';
    case 'finished':
      return 'Journée terminée';
    case 'present':
    case 'on_time':
      return 'Présent';
    default:
      return 'À vérifier';
  }
}

String _comparisonLabel(String status) {
  switch (status) {
    case 'late':
      return 'Retard';
    case 'absent':
    case 'missing':
      return 'Absent';
    case 'unexpected':
    case 'not_planned':
      return 'Non prévu';
    case 'on_break':
      return 'Pause';
    case 'finished':
      return 'Terminé';
    case 'present':
    case 'on_time':
      return 'Présent';
    default:
      return 'À vérifier';
  }
}

Color _comparisonColor(String status) {
  switch (status) {
    case 'present':
    case 'on_time':
      return AppColors.success;
    case 'late':
    case 'on_break':
      return AppColors.warning;
    case 'absent':
    case 'missing':
      return AppColors.danger;
    case 'unexpected':
    case 'not_planned':
      return CupertinoColors.systemIndigo;
    default:
      return AppColors.subtitle;
  }
}

IconData _comparisonIcon(String status) {
  switch (status) {
    case 'present':
    case 'on_time':
      return CupertinoIcons.check_mark_circled_solid;
    case 'late':
      return CupertinoIcons.clock_fill;
    case 'absent':
    case 'missing':
      return CupertinoIcons.xmark_circle_fill;
    case 'unexpected':
    case 'not_planned':
      return CupertinoIcons.plus_circle_fill;
    case 'on_break':
      return CupertinoIcons.pause_circle_fill;
    case 'finished':
      return CupertinoIcons.flag_circle_fill;
    default:
      return CupertinoIcons.question_circle_fill;
  }
}

Color _alertColor(String type) {
  switch (type) {
    case 'absent':
    case 'missing_clock_out':
    case 'error':
      return AppColors.danger;
    case 'late':
    case 'long_break':
    case 'warning':
      return AppColors.warning;
    case 'unexpected':
      return CupertinoColors.systemIndigo;
    default:
      return AppColors.subtitle;
  }
}

IconData _alertIcon(String type) {
  switch (type) {
    case 'absent':
      return CupertinoIcons.person_crop_circle_badge_exclam;
    case 'late':
      return CupertinoIcons.clock_fill;
    case 'long_break':
      return CupertinoIcons.pause_circle_fill;
    case 'missing_clock_out':
      return CupertinoIcons.square_arrow_right_fill;
    case 'unexpected':
      return CupertinoIcons.plus_circle_fill;
    default:
      return CupertinoIcons.exclamationmark_triangle_fill;
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'present':
      return 'Présent';
    case 'on_break':
      return 'Pause';
    case 'finished':
      return 'Terminé';
    case 'not_clocked':
      return 'Non pointé';
    default:
      return 'Tous';
  }
}

Color _statusColor(String? status) {
  switch (status) {
    case 'present':
      return AppColors.success;
    case 'on_break':
      return AppColors.warning;
    case 'finished':
      return AppColors.subtitle;
    case 'not_clocked':
      return AppColors.danger;
    default:
      return AppColors.subtitle;
  }
}

IconData _statusIcon(String? status) {
  switch (status) {
    case 'present':
      return CupertinoIcons.check_mark_circled_solid;
    case 'on_break':
      return CupertinoIcons.pause_circle_fill;
    case 'finished':
      return CupertinoIcons.flag_circle_fill;
    case 'not_clocked':
      return CupertinoIcons.clock_fill;
    default:
      return CupertinoIcons.person_2_fill;
  }
}

String? _eventToStatus(String type) {
  switch (type) {
    case 'clock_in':
      return 'present';
    case 'pause_start':
    case 'pause_end':
      return 'on_break';
    case 'clock_out':
      return 'finished';
    default:
      return null;
  }
}

String _eventLabel(String type) {
  switch (type) {
    case 'clock_in':
      return 'est arrivé';
    case 'pause_start':
      return 'commence sa pause';
    case 'pause_end':
      return 'reprend son travail';
    case 'clock_out':
      return 'termine sa journée';
    default:
      return 'activité enregistrée';
  }
}

String _formatApiTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return _hhmm(parsed.toLocal());

  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (match != null) {
    return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
  }

  return raw;
}

String _hhmm(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formattedDate(DateTime date) {
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

DateTime? _plannedStartDateTime(Map<String, dynamic> employee) {
  final raw = (
    employee['planned_start'] ??
    employee['start_time'] ??
    employee['schedule_start'] ??
    ''
  ).toString().trim();

  if (raw.isEmpty) return null;

  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);

  if (match == null) return null;

  final now = DateTime.now();

  return DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

bool _isEmployeeLate(
  Map<String, dynamic> employee, {
  int graceMinutes = 10,
}) {
  if (employee['status']?.toString() != 'not_clocked') {
    return false;
  }

  final plannedStart = _plannedStartDateTime(employee);

  if (plannedStart == null) return false;

  final lateThreshold = plannedStart.add(
    Duration(minutes: graceMinutes),
  );

  return DateTime.now().isAfter(lateThreshold);
}

bool _isEmployeeAbsent(
  Map<String, dynamic> employee, {
  int absenceAfterMinutes = 60,
}) {
  if (employee['status']?.toString() != 'not_clocked') {
    return false;
  }

  final plannedStart = _plannedStartDateTime(employee);

  if (plannedStart == null) return false;

  final absenceThreshold = plannedStart.add(
    Duration(minutes: absenceAfterMinutes),
  );

  return DateTime.now().isAfter(absenceThreshold);
}
