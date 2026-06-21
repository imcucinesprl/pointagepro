import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';
import 'clock_scan_screen.dart';
import '../../core/services/session_service.dart';
import '../../core/services/pointage_service.dart';
import 'dart:async';


class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  Timer? _refreshTimer;
  String firstName = '';
  String companyName = '';
  String todayStatus = 'not_clocked';
  String arrivalTime = '--:--';
  String pauseTime = '--:--';
  String departureTime = '--:--';

@override
void initState() {
  super.initState();

  loadPointageData();
  loadSession();

_refreshTimer = Timer.periodic(
  const Duration(seconds: 10),
  (_) => loadPointageData(),
);
}
@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}

  Future<void> loadSession() async {
    final savedFirstName = await SessionService.getFirstName();
    final savedCompanyName = await SessionService.getCompanyName();

    if (!mounted) return;

    setState(() {
      firstName = savedFirstName;
      companyName = savedCompanyName;
    });
  }

Future<void> performClock() async {
  final result = await PointageService.clock();

  if (result["success"] == true) {
    await loadPointageData();
    await loadSession();
  }

  if (!mounted) return;

  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(
        result["success"] == true ? "Pointage enregistré" : "Erreur",
      ),
      content: Text(
        result["message"]?.toString() ?? "",
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text("OK"),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

Future<void> loadPointageData() async {

  final result = await PointageService.me();

  if (!mounted || result["success"] != true) return;

  final pointages = result["pointages"] as List<dynamic>;

  String arrival = '--:--';
  String pause = '--:--';
  String departure = '--:--';

  for (final p in pointages) {
    final type = p["type"];
    final createdAt = DateTime.tryParse(p["created_at"].toString());

    if (createdAt == null) continue;

    final time =
        "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";

    if (type == "clock_in") arrival = time;
    if (type == "pause_start") pause = time;
    if (type == "clock_out") departure = time;
  }

  setState(() {
    todayStatus = result["today_status"] ?? 'not_clocked';
    arrivalTime = arrival;
    pauseTime = pause;
    departureTime = departure;
  });
}

Future<void> performClockOut() async {
  final result = await PointageService.clockOut();

  if (result["success"] == true) {
    await loadPointageData();
  }

  if (!mounted) return;

  showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(result["success"] == true ? "Départ enregistré" : "Erreur"),
      content: Text(result["message"]?.toString() ?? ""),
      actions: [
        CupertinoDialogAction(
          child: const Text("OK"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (todayStatus) {
  'present' => 'Présent',
  'on_break' => 'En pause',
  'finished' => 'Journée terminée',
  _ => 'Non pointé',
};

final statusColor = switch (todayStatus) {
  'present' => AppColors.success,
  'on_break' => AppColors.warning,
  'finished' => AppColors.subtitle,
  _ => AppColors.danger,
};

final statusDescription = switch (todayStatus) {
  'present' => 'Vous êtes actuellement en service.',
  'on_break' => 'Pause en cours.',
  'finished' => 'Votre journée est terminée.',
  _ => 'Aucun pointage enregistré aujourd’hui.',
};
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(middle: Text('PointagePro')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 18),

            Text(
              firstName.isEmpty ? 'Bonjour 👋' : 'Bonjour $firstName 👋',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              companyName.isEmpty
                  ? 'Prêt à commencer ta journée ?'
                  : companyName,
              style: TextStyle(fontSize: 17, color: AppColors.subtitle),
            ),

            const SizedBox(height: 24),

            IosCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut actuel',
                    style: TextStyle(fontSize: 15, color: AppColors.subtitle),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
    Container(
  width: 14,
  height: 14,
  decoration: BoxDecoration(
    color: statusColor,
    shape: BoxShape.circle,
  ),
),
                      const SizedBox(width: 10),
                      Text(
  statusLabel,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                    ),
child: Row(
  children: [
    const Icon(
      CupertinoIcons.clock,
      color: AppColors.primary,
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Text(
        statusDescription,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.subtitle,
        ),
      ),
    ),
  ],
),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            CupertinoButton(
              padding: EdgeInsets.zero,
onPressed: () async {
  final result = await Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (_) => const ClockScanScreen(),
    ),
  );

  if (result == true) {
    await loadPointageData();
    await loadSession();
  }
},
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.qrcode_viewfinder,
                      color: CupertinoColors.white,
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pointer maintenant',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Aujourd’hui',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            IosCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: CupertinoIcons.arrow_right_circle,
                    title: 'Arrivée',
                    value: arrivalTime,
                    color: AppColors.success,
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: CupertinoIcons.pause_circle,
                    title: 'Pause',
                    value: pauseTime,
                    color: AppColors.warning,
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: CupertinoIcons.arrow_left_circle,
                    title: 'Départ',
                    value: departureTime,
                    color: statusColor,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
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
