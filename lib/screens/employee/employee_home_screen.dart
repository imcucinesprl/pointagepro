import 'package:flutter/cupertino.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/ios_card.dart';
import 'clock_scan_screen.dart';
import '../../core/services/session_service.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String firstName = '';
  String companyName = '';

  @override
  void initState() {
    super.initState();
    loadSession();
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

  @override
  Widget build(BuildContext context) {
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
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Non pointé',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
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
                    child: const Row(
                      children: [
                        Icon(CupertinoIcons.clock, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aucun pointage enregistré aujourd’hui.',
                            style: TextStyle(
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
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ClockScanScreen()),
                );
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
                    value: '--:--',
                    color: AppColors.success,
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: CupertinoIcons.pause_circle,
                    title: 'Pause',
                    value: '--:--',
                    color: AppColors.warning,
                  ),
                  _Divider(),
                  _InfoRow(
                    icon: CupertinoIcons.arrow_left_circle,
                    title: 'Départ',
                    value: '--:--',
                    color: AppColors.danger,
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
