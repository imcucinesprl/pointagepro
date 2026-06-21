import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';

class ManagerPlanningScreen extends StatefulWidget {
  final int companyId;

  const ManagerPlanningScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<ManagerPlanningScreen> createState() => _ManagerPlanningScreenState();
}

class _ManagerPlanningScreenState extends State<ManagerPlanningScreen> {
  bool isLoading = true;
  String? errorMessage;

  DateTime weekStart = _startOfWeek(DateTime.now());
  List<dynamic> days = [];

  final String baseUrl = "https://taskflowapp.eu/pointagepro";

  static DateTime _startOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day - (date.weekday - 1),
    );
  }

  @override
  void initState() {
    super.initState();
    loadPlanning();
  }

  String get weekStartString {
    return "${weekStart.year.toString().padLeft(4, '0')}-"
        "${weekStart.month.toString().padLeft(2, '0')}-"
        "${weekStart.day.toString().padLeft(2, '0')}";
  }

Future<void> loadPlanning() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final response = await http.get(
      Uri.parse(
        "$baseUrl/planning_comparison.php"
        "?company_id=${widget.companyId}"
        "&week_start=$weekStartString",
      ),
    );

    final data = jsonDecode(response.body);

    if (!mounted) return;

    if (response.statusCode == 200 &&
        data["success"] == true) {
      setState(() {
        days = List<dynamic>.from(
          data["days"] ?? [],
        );
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage =
            data["message"] ?? "Erreur inconnue";
        isLoading = false;
      });
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      errorMessage = e.toString();
      isLoading = false;
    });
  }
}

  void previousWeek() {
    setState(() {
      weekStart = weekStart.subtract(const Duration(days: 7));
    });
    loadPlanning();
  }

  void nextWeek() {
    setState(() {
      weekStart = weekStart.add(const Duration(days: 7));
    });
    loadPlanning();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Planning"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: loadPlanning,
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ErrorBox(message: errorMessage!),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: loadPlanning,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Planning',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Organisation de la semaine.',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.subtitle,
                  ),
                ),
                const SizedBox(height: 20),
                _WeekSelector(
                  weekStart: weekStart,
                  onPrevious: previousWeek,
                  onNext: nextWeek,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final day = days[index];
                return _DayPlanningCard(day: day);
              },
              childCount: days.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _WeekSelector({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: onPrevious,
            child: const Icon(CupertinoIcons.chevron_left),
          ),
          Expanded(
            child: Text(
              "${formatDate(weekStart)} - ${formatDate(weekEnd)}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: onNext,
            child: const Icon(CupertinoIcons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _DayPlanningCard extends StatelessWidget {
  final Map day;

  const _DayPlanningCard({
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final employees = (day["employees"] as List? ?? []).where((employee) {
  final start = employee["planned_start"]?.toString() ?? "";
  final end = employee["planned_end"]?.toString() ?? "";

  return start.isNotEmpty && end.isNotEmpty;
}).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
  "${day["day_of_week"]} ${formatDate(day["date"]?.toString())}",
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            if (employees.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "Aucun employé prévu",
                  style: TextStyle(
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              for (int i = 0; i < employees.length; i++) ...[
                _EmployeePlanningRow(employee: employees[i]),
                if (i != employees.length - 1) const _Divider(),
              ],
          ],
        ),
      ),
    );
  }

  String formatDate(String? date) {
    if (date == null || date.length < 10) return "";
    final parts = date.split("-");
    return "${parts[2]}/${parts[1]}";
  }
}

class _EmployeePlanningRow extends StatelessWidget {
  final Map employee;

  const _EmployeePlanningRow({
    required this.employee,
  });

  String get fullName {
    return employee["full_name"]?.toString() ?? "Employé";
  }

  String cleanTime(dynamic value) {
    if (value == null) return "";
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String statusLabel(String status) {
    switch (status) {
      case "present":
        return "Présent";
      case "conge":
        return "Congé";
      case "malade":
        return "Maladie";
      case "vacances":
        return "Vacances";
      case "bakery-time":
        return "Boulangerie";
      case "caisse-time":
        return "Caisse";
      case "cremerie":
        return "Crémerie";
      case "boucherie":
        return "Boucherie";
      case "fruits-legumes":
        return "Fruits & légumes";
      case "recup":
        return "Récup";
      case "jf":
        return "Jour férié";
      case "ai":
        return "Absence injustifiée";
      default:
        return status.isEmpty ? "Repos" : status;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "bakery-time":
        return CupertinoColors.systemOrange;
      case "caisse-time":
        return CupertinoColors.systemTeal;
      case "boucherie":
        return CupertinoColors.systemRed;
      case "fruits-legumes":
        return CupertinoColors.systemGreen;
      case "cremerie":
        return CupertinoColors.systemIndigo;
      case "conge":
      case "vacances":
      case "jf":
        return CupertinoColors.systemBlue;
      case "malade":
      case "ai":
        return CupertinoColors.systemRed;
      case "recup":
        return CupertinoColors.systemPurple;
      default:
        return AppColors.subtitle;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "bakery-time":
        return CupertinoIcons.cube_box_fill;
      case "caisse-time":
        return CupertinoIcons.creditcard_fill;
      case "boucherie":
        return CupertinoIcons.scissors;
      case "fruits-legumes":
        return CupertinoIcons.leaf_arrow_circlepath;
      case "cremerie":
        return CupertinoIcons.drop_fill;
      case "conge":
      case "vacances":
        return CupertinoIcons.sun_max_fill;
      case "malade":
        return CupertinoIcons.bandage_fill;
      case "jf":
        return CupertinoIcons.flag_fill;
      case "recup":
        return CupertinoIcons.arrow_counterclockwise;
      case "ai":
        return CupertinoIcons.exclamationmark_triangle_fill;
      default:
        return CupertinoIcons.moon_fill;
    }
  }

  Color differenceColor(int? difference) {
    if (difference == null) return AppColors.subtitle;

    final abs = difference.abs();

    if (abs <= 5) {
      return CupertinoColors.systemGreen;
    }

    if (abs <= 15) {
      return CupertinoColors.systemOrange;
    }

    return CupertinoColors.systemRed;
  }

  String differenceText(int? difference) {
    if (difference == null) return "-";

    if (difference == 0) {
      return "Conforme";
    }

    return "${difference > 0 ? "+" : ""}$difference min";
  }

  @override
  Widget build(BuildContext context) {
    final status = employee["planned_status"]?.toString() ?? "";
    final color = statusColor(status);

    final plannedStart = cleanTime(employee["planned_start"]);
    final plannedEnd = cleanTime(employee["planned_end"]);

    final realStart = cleanTime(employee["real_clock_in"]);
    final realEnd = cleanTime(employee["real_clock_out"]);

    final rawDifference = employee["difference_minutes"];
    final int? difference = rawDifference == null
        ? null
        : int.tryParse(rawDifference.toString());

    final plannedText = plannedStart.isNotEmpty && plannedEnd.isNotEmpty
        ? "$plannedStart → $plannedEnd"
        : statusLabel(status);

    final realText = realStart.isNotEmpty
        ? "$realStart${realEnd.isNotEmpty ? " → $realEnd" : ""}"
        : "Aucun pointage";

    final diffColor = differenceColor(difference);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              statusIcon(status),
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
                  fullName.isEmpty ? "Employé" : fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Prévu : $plannedText",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "Réel : $realText",
                  style: TextStyle(
                    fontSize: 14,
                    color: realStart.isEmpty
                        ? CupertinoColors.systemRed
                        : AppColors.subtitle,
                    fontWeight: realStart.isEmpty
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  "Écart : ${differenceText(difference)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: diffColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              statusLabel(status),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.softBorder),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: CupertinoColors.systemRed,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}