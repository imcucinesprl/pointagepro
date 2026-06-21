import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/app_colors.dart';

class AdminHoursStatsScreen extends StatefulWidget {
  final int companyId;

  const AdminHoursStatsScreen({
    super.key,
    required this.companyId,
  });

  @override
  State<AdminHoursStatsScreen> createState() => _AdminHoursStatsScreenState();
}

class _AdminHoursStatsScreenState extends State<AdminHoursStatsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> employees = [];

  final String baseUrl = "https://taskflowapp.eu/pointagepro";

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/admin_hours_stats.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "company_id": widget.companyId,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          employees = data["employees"] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text("Statistiques des heures"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: loadStats,
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

    if (employees.isEmpty) {
      return const Center(
        child: Text(
          "Aucun employé trouvé",
          style: TextStyle(
            color: AppColors.subtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: loadStats,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Heures prestées",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Résumé des prestations par employé.",
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final employee = employees[index];
                return EmployeeStatsCard(employee: employee);
              },
              childCount: employees.length,
            ),
          ),
        ),
      ],
    );
  }
}

class EmployeeStatsCard extends StatelessWidget {
  final Map employee;

  const EmployeeStatsCard({
    super.key,
    required this.employee,
  });

  String get fullName {
    final firstname = employee["firstname"]?.toString() ?? "";
    final lastname = employee["lastname"]?.toString() ?? "";
    return "$firstname $lastname".trim();
  }

  String statusLabel(String status) {
    switch (status) {
      case "working":
        return "En service";
      case "pause":
        return "En pause";
      case "finished":
        return "Terminé";
      default:
        return "Absent";
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "working":
        return CupertinoColors.systemGreen;
      case "pause":
        return CupertinoColors.systemOrange;
      case "finished":
        return CupertinoColors.systemGrey;
      default:
        return CupertinoColors.systemRed;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case "working":
        return CupertinoIcons.play_circle_fill;
      case "pause":
        return CupertinoIcons.pause_circle_fill;
      case "finished":
        return CupertinoIcons.check_mark_circled_solid;
      default:
        return CupertinoIcons.xmark_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = employee["status"]?.toString() ?? "absent";
    final color = statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.softBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon(status),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullName.isEmpty ? "Employé" : fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatBox(
                  title: "Aujourd'hui",
                  value: employee["today"]?.toString() ?? "00h00",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  title: "Semaine",
                  value: employee["week"]?.toString() ?? "00h00",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatBox(
                  title: "Mois",
                  value: employee["month"]?.toString() ?? "00h00",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatBox extends StatelessWidget {
  final String title;
  final String value;

  const StatBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ],
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