import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'clock_scan_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(middle: Text('PointagePro')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 20),

            const Text(
              'Bonjour',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Voici ton pointage du jour.',
              style: TextStyle(fontSize: 17, color: Color(0xFF6B7280)),
            ),

            const SizedBox(height: 24),

            _statusCard(),

            const SizedBox(height: 24),

            _clockButton(
              context,
              title: 'Pointer maintenant',
              subtitle: 'Scanner le QR Code du magasin',
              icon: CupertinoIcons.qrcode_viewfinder,
              color: const Color(0xFF007AFF),
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const ClockScanScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            _clockButton(
              context,
              title: 'Voir mon historique',
              subtitle: 'Mes pointages récents',
              icon: CupertinoIcons.time,
              color: const Color(0xFF34C759),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statut actuel',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Non pointé',
            style: TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Aucun pointage enregistré aujourd’hui.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
          ),
        ],
      ),
    );
  }

  static Widget _clockButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
