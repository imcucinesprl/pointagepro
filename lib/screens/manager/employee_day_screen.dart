import 'package:flutter/cupertino.dart';

import '../../core/services/manager_service.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';

class EmployeeDayScreen extends StatefulWidget {
  final int userId;

  const EmployeeDayScreen({
    super.key,
    required this.userId,
  });

  @override
  State<EmployeeDayScreen> createState() => _EmployeeDayScreenState();
}

class _EmployeeDayScreenState extends State<EmployeeDayScreen> {
  bool isLoading = true;
  String? errorMessage;

  String employeeName = '';
  List<dynamic> pointages = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final result = await ManagerService.employeeDay(userId: widget.userId);

    if (!mounted) return;

    if (result["success"] != true) {
      setState(() {
        isLoading = false;
        errorMessage = result["message"]?.toString() ?? "Erreur inconnue";
      });
      return;
    }

    setState(() {
      employeeName = result["employee"]?["name"]?.toString() ?? "Employé";
      pointages = result["pointages"] ?? [];
      isLoading = false;
    });
  }

  String labelForType(String type) {
    switch (type) {
      case "clock_in":
        return "Arrivée";
      case "pause_start":
        return "Début de pause";
      case "pause_end":
        return "Fin de pause";
      case "clock_out":
        return "Départ";
      default:
        return type;
    }
  }

  IconData iconForType(String type) {
    switch (type) {
      case "clock_in":
        return CupertinoIcons.arrow_right_circle;
      case "pause_start":
        return CupertinoIcons.pause_circle;
      case "pause_end":
        return CupertinoIcons.play_circle;
      case "clock_out":
        return CupertinoIcons.arrow_left_circle;
      default:
        return CupertinoIcons.clock;
    }
  }

  Color colorForType(String type) {
    switch (type) {
      case "clock_in":
        return AppColors.success;
      case "pause_start":
        return AppColors.warning;
      case "pause_end":
        return AppColors.primary;
      case "clock_out":
        return AppColors.subtitle;
      default:
        return AppColors.subtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(employeeName.isEmpty ? "Détail" : employeeName),
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
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Pointages d’aujourd’hui",
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 24),
                      IosCard(
                        child: pointages.isEmpty
                            ? const Text(
                                "Aucun pointage aujourd’hui",
                                style: TextStyle(
                                  color: AppColors.subtitle,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0; i < pointages.length; i++) ...[
                                    _PointageRow(
                                      title: labelForType(
                                        pointages[i]["type"]?.toString() ?? "",
                                      ),
                                      time: pointages[i]["time"]?.toString() ?? "--:--",
                                      icon: iconForType(
                                        pointages[i]["type"]?.toString() ?? "",
                                      ),
                                      color: colorForType(
                                        pointages[i]["type"]?.toString() ?? "",
                                      ),
                                    ),
                                    if (i != pointages.length - 1)
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

class _PointageRow extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _PointageRow({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.subtitle,
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