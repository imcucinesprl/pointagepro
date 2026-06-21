import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';

class EmployeePlanningScreen extends StatefulWidget {
  final int companyId;
  final int userId;

  const EmployeePlanningScreen({
    super.key,
    required this.companyId,
    required this.userId,
  });

  @override
  State<EmployeePlanningScreen> createState() => _EmployeePlanningScreenState();
}

class _EmployeePlanningScreenState extends State<EmployeePlanningScreen> {
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

  String get weekStartString {
    return "${weekStart.year.toString().padLeft(4, '0')}-"
        "${weekStart.month.toString().padLeft(2, '0')}-"
        "${weekStart.day.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    loadPlanning();
  }

  Future<void> loadPlanning() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/employee_planning.php"
          "?company_id=${widget.companyId}"
          "&user_id=${widget.userId}"
          "&week_start=$weekStartString",
        ),
      );

      print("EMPLOYEE PLANNING STATUS: ${response.statusCode}");
print("EMPLOYEE PLANNING BODY: ${response.body}");

if (!response.body.trim().startsWith("{")) {
  throw Exception("Réponse serveur non JSON : ${response.body}");
}

final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          days = List<dynamic>.from(data["days"] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = data["message"] ?? "Erreur inconnue";
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
        middle: const Text("Mon planning"),
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
      return const Center(child: CupertinoActivityIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            style: const TextStyle(
              color: CupertinoColors.systemRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        const Text(
          "Mon planning",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Tes horaires prévus pour la semaine.",
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
        const SizedBox(height: 20),
        if (days.isEmpty)
          const _EmptyBox()
        else
          for (final day in days) _PlanningDayCard(day: day),
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

class _PlanningDayCard extends StatelessWidget {
  final Map day;

  const _PlanningDayCard({
    required this.day,
  });

  String cleanTime(dynamic value) {
    if (value == null) return "";
    final text = value.toString();
    if (text.length >= 5) return text.substring(0, 5);
    return text;
  }

  String formatDate(String? date) {
    if (date == null || date.length < 10) return "";
    final parts = date.split("-");
    return "${parts[2]}/${parts[1]}";
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

  @override
  Widget build(BuildContext context) {
    final status = day["status"]?.toString() ?? "";
    final start = cleanTime(day["start_time"]);
    final end = cleanTime(day["end_time"]);
    final color = statusColor(status);

    final hasHours = start.isNotEmpty && end.isNotEmpty;

    final timeText = hasHours
        ? "$start → $end"
        : statusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              statusIcon(status),
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${day["day_of_week"] ?? ""} ${formatDate(day["date"]?.toString())}",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 17,
                    color: hasHours ? AppColors.text : AppColors.subtitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel(status),
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
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

class _EmptyBox extends StatelessWidget {
  const _EmptyBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: const Text(
        "Aucun planning trouvé pour cette semaine.",
        style: TextStyle(
          color: AppColors.subtitle,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}