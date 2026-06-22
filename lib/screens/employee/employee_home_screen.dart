import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/services/pointage_service.dart';
import '../../core/services/session_service.dart';
import 'clock_scan_screen.dart';
import 'employee_week_summary_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color red = Color(0xFFFF3B30);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  Timer? _refreshTimer;

  String firstName = '';
  String companyName = '';
  String todayStatus = 'not_clocked';

  String arrivalTime = '--:--';
  String pauseTime = '--:--';
  String departureTime = '--:--';

  double? distanceMeters;
  double? gpsAccuracy;
  int allowedRadius = 100;

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

    final storeSettings = result["store_settings"] as Map<String, dynamic>?;

    setState(() {
      todayStatus = result["today_status"] ?? 'not_clocked';
      arrivalTime = arrival;
      pauseTime = pause;
      departureTime = departure;

      allowedRadius = int.tryParse(
            storeSettings?["allowed_radius"]?.toString() ?? "100",
          ) ??
          100;

      distanceMeters = double.tryParse(
        result["distance_meters"]?.toString() ?? "",
      );

      gpsAccuracy = double.tryParse(
        result["gps_accuracy"]?.toString() ?? "",
      );
    });
  }

Future<void> openScanner() async {
  await Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (_) => const ClockScanScreen(),
    ),
  );

  if (!mounted) return;

  await loadPointageData();
  await loadSession();
}

  Future<void> openWeekSummary() async {
    final userId = await SessionService.getUserId();
    final companyId = await SessionService.getCompanyId();

    if (userId == null || companyId == null) {
      if (!mounted) return;

      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text("Session invalide"),
          content: const Text(
            "Impossible de récupérer l'utilisateur ou la société.",
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => EmployeeWeekSummaryScreen(
          userId: userId,
          companyId: companyId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (todayStatus) {
      'present' => 'En cours',
      'on_break' => 'En pause',
      'finished' => 'Terminé',
      _ => 'Non pointé',
    };

    final statusColor = switch (todayStatus) {
      'present' => green,
      'on_break' => orange,
      'finished' => subtitle,
      _ => red,
    };

    final statusDescription = switch (todayStatus) {
      'present' => 'Vous êtes actuellement en service.',
      'on_break' => 'Pause en cours.',
      'finished' => 'Votre journée est terminée.',
      _ => 'Prêt à commencer votre journée ?',
    };

    final isOnSite =
        distanceMeters != null && distanceMeters! <= allowedRadius;

    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xCCF3F6FB),
        border: null,
        middle: Text(
          'PointagePro',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _BlurCircle(
                size: 260,
                color: blue.withOpacity(0.20),
              ),
            ),
            Positioned(
              top: 220,
              left: -120,
              child: _BlurCircle(
                size: 280,
                color: purple.withOpacity(0.16),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -90,
              child: _BlurCircle(
                size: 280,
                color: green.withOpacity(0.13),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
              children: [
                _HeroCard(
                  firstName: firstName,
                  companyName: companyName,
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        iconColor: green,
                        title: 'Scanner QR Code',
                        subtitle: 'Pointer maintenant',
                        onTap: openScanner,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionCard(
                        icon: CupertinoIcons.calendar,
                        iconColor: blue,
                        title: 'Résumé semaine',
                        subtitle: 'Voir le détail',
                        onTap: openWeekSummary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _PresenceCard(
                  isOnSite: isOnSite,
                  distanceMeters: distanceMeters,
                  allowedRadius: allowedRadius,
                  gpsAccuracy: gpsAccuracy,
                ),
                const SizedBox(height: 18),
                _DayCard(
                  statusColor: statusColor,
                  statusLabel: statusLabel,
                  statusDescription: statusDescription,
                  arrivalTime: arrivalTime,
                  pauseTime: pauseTime,
                  departureTime: departureTime,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.firstName,
    required this.companyName,
    required this.statusLabel,
    required this.statusColor,
  });

  final String firstName;
  final String companyName;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A84FF).withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bonjour 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstName.isEmpty ? 'Employé' : firstName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            companyName.isEmpty
                ? 'Prêt à commencer votre journée ?'
                : companyName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatusPill(
                label: 'Employé',
                color: Colors.white,
                textColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.20),
              ),
              const Spacer(),
              _StatusPill(
                label: statusLabel,
                color: statusColor,
                textColor: const Color(0xFF4C1D95),
                backgroundColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.20),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Heure actuelle',
                  value: time,
                ),
              ),
              Container(
                height: 48,
                width: 1,
                color: Colors.white.withOpacity(0.24),
              ),
              const Expanded(
                child: _HeroMetric(
                  label: 'Statut aujourd’hui',
                  value: 'Actif',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: _GlassCard(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          height: 125,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBubble(icon: icon, color: iconColor),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: _EmployeeHomeScreenState.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: _EmployeeHomeScreenState.subtitle,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right_circle_fill,
                    color: iconColor.withOpacity(0.75),
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({
    required this.isOnSite,
    required this.distanceMeters,
    required this.allowedRadius,
    required this.gpsAccuracy,
  });

  final bool isOnSite;
  final double? distanceMeters;
  final int allowedRadius;
  final double? gpsAccuracy;

  @override
  Widget build(BuildContext context) {
    final color = distanceMeters == null
        ? _EmployeeHomeScreenState.orange
        : isOnSite
            ? _EmployeeHomeScreenState.green
            : _EmployeeHomeScreenState.red;

    final status = distanceMeters == null
        ? 'Position inconnue'
        : isOnSite
            ? 'Sur site'
            : 'Hors zone';

    final infoText = distanceMeters == null
        ? "La distance sera affichée après le prochain pointage."
        : isOnSite
            ? "Vous êtes dans la zone autorisée."
            : "Vous êtes hors de la zone autorisée.";

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBubble(
                icon: CupertinoIcons.location_fill,
                color: _EmployeeHomeScreenState.purple,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ma présence',
                  style: TextStyle(
                    color: _EmployeeHomeScreenState.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: status,
                color: color,
                textColor: color,
                backgroundColor: color.withOpacity(0.12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Radar(color: color),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PresenceMetric(
                      label: 'Distance du magasin',
                      value: distanceMeters == null
                          ? '--'
                          : '${distanceMeters!.round()} m',
                      color: color,
                    ),
                    const SizedBox(height: 12),
                    _PresenceMetric(
                      label: 'Rayon autorisé',
                      value: '$allowedRadius m',
                      color: _EmployeeHomeScreenState.text,
                    ),
                    const SizedBox(height: 12),
                    _PresenceMetric(
                      label: 'Précision GPS',
                      value: gpsAccuracy == null
                          ? '--'
                          : '± ${gpsAccuracy!.round()} m',
                      color: _EmployeeHomeScreenState.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _IconBubble(
                  icon: CupertinoIcons.info_circle_fill,
                  color: color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    infoText,
                    style: const TextStyle(
                      color: _EmployeeHomeScreenState.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.statusColor,
    required this.statusLabel,
    required this.statusDescription,
    required this.arrivalTime,
    required this.pauseTime,
    required this.departureTime,
  });

  final Color statusColor;
  final String statusLabel;
  final String statusDescription;
  final String arrivalTime;
  final String pauseTime;
  final String departureTime;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const _IconBubble(
                icon: CupertinoIcons.calendar_today,
                color: _EmployeeHomeScreenState.purple,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ma journée',
                  style: TextStyle(
                    color: _EmployeeHomeScreenState.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(
                label: statusLabel,
                color: statusColor,
                textColor: statusColor,
                backgroundColor: statusColor.withOpacity(0.12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock_fill,
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusDescription,
                    style: const TextStyle(
                      color: _EmployeeHomeScreenState.subtitle,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _TimelineRow(
            icon: CupertinoIcons.arrow_right,
            title: 'Arrivée',
            value: arrivalTime,
            color: _EmployeeHomeScreenState.blue,
            isDone: arrivalTime != '--:--',
          ),
          _SoftDivider(),
          _TimelineRow(
            icon: CupertinoIcons.pause_circle_fill,
            title: 'Début de pause',
            value: pauseTime,
            color: _EmployeeHomeScreenState.orange,
            isDone: pauseTime != '--:--',
          ),
          _SoftDivider(),
          _TimelineRow(
            icon: CupertinoIcons.arrow_left,
            title: 'Départ',
            value: departureTime,
            color: _EmployeeHomeScreenState.green,
            isDone: departureTime != '--:--',
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDone,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(
          icon: icon,
          color: isDone ? color : const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _EmployeeHomeScreenState.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _StatusPill(
          label: isDone ? value : 'En attente',
          color: isDone ? color : const Color(0xFF9CA3AF),
          textColor: isDone ? color : const Color(0xFF6B7280),
          backgroundColor:
              (isDone ? color : const Color(0xFF9CA3AF)).withOpacity(0.12),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.055),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.78),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PresenceMetric extends StatelessWidget {
  const _PresenceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _EmployeeHomeScreenState.subtitle,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final size in [118.0, 88.0, 58.0])
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.08),
                border: Border.all(color: color.withOpacity(0.18)),
              ),
            ),
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(
        height: 1,
        color: const Color(0xFFE5E7EB),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}