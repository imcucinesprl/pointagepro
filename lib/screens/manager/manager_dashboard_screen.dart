import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(middle: Text('Manager')),
      child: SafeArea(
        child: ListView(
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
              style: TextStyle(fontSize: 17, color: AppColors.subtitle),
            ),

            const SizedBox(height: 24),

            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: 'Présents',
                    value: '8',
                    color: AppColors.success,
                    icon: CupertinoIcons.check_mark_circled_solid,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pause',
                    value: '2',
                    color: AppColors.warning,
                    icon: CupertinoIcons.pause_circle_fill,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    title: 'Absents',
                    value: '1',
                    color: AppColors.danger,
                    icon: CupertinoIcons.xmark_circle_fill,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Non pointés',
                    value: '3',
                    color: AppColors.subtitle,
                    icon: CupertinoIcons.clock_fill,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Équipe aujourd’hui',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 12),

            IosCard(
              child: Column(
                children: const [
                  _EmployeePresenceRow(
                    name: 'Luca',
                    detail: 'Arrivé à 08:02',
                    status: 'Présent',
                    color: AppColors.success,
                    icon: CupertinoIcons.check_mark_circled_solid,
                  ),
                  _Divider(),
                  _EmployeePresenceRow(
                    name: 'Sarah',
                    detail: 'En pause depuis 12:14',
                    status: 'Pause',
                    color: AppColors.warning,
                    icon: CupertinoIcons.pause_circle_fill,
                  ),
                  _Divider(),
                  _EmployeePresenceRow(
                    name: 'Marco',
                    detail: 'Prévu à 09:00',
                    status: 'Absent',
                    color: AppColors.danger,
                    icon: CupertinoIcons.xmark_circle_fill,
                  ),
                  _Divider(),
                  _EmployeePresenceRow(
                    name: 'David',
                    detail: 'Aucun pointage',
                    status: 'Non pointé',
                    color: AppColors.subtitle,
                    icon: CupertinoIcons.clock_fill,
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IosCard(
      padding: const EdgeInsets.all(18),
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
    );
  }
}

class _EmployeePresenceRow extends StatelessWidget {
  final String name;
  final String detail;
  final String status;
  final Color color;
  final IconData icon;

  const _EmployeePresenceRow({
    required this.name,
    required this.detail,
    required this.status,
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
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(fontSize: 14, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
        Text(
          status,
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
