import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xCCF3F6FB),
        border: null,
        middle: Text(
          'Abonnement',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
          children: const [
            _SubscriptionHeroCard(),
            SizedBox(height: 18),
            _SubscriptionInfoCard(),
            SizedBox(height: 18),
            _PlansCard(),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionHeroCard extends StatelessWidget {
  const _SubscriptionHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SubscriptionScreen.blue, SubscriptionScreen.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.star_fill, color: Colors.white, size: 42),
          SizedBox(height: 18),
          Text(
            'PointagePro PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Votre abonnement PointagePro est indépendant de TaskFlow.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  const _SubscriptionInfoCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: const [
          _InfoRow(
            icon: CupertinoIcons.checkmark_seal_fill,
            color: SubscriptionScreen.green,
            title: 'Statut',
            value: 'Essai gratuit',
          ),
          _SoftDivider(),
          _InfoRow(
            icon: CupertinoIcons.calendar,
            color: SubscriptionScreen.orange,
            title: 'Fin de l’essai',
            value: '--',
          ),
          _SoftDivider(),
          _InfoRow(
            icon: CupertinoIcons.creditcard_fill,
            color: SubscriptionScreen.blue,
            title: 'Facturation',
            value: 'Non configurée',
          ),
        ],
      ),
    );
  }
}

class _PlansCard extends StatelessWidget {
  const _PlansCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Formules disponibles',
            style: TextStyle(
              color: SubscriptionScreen.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          _PlanRow(title: 'Gratuit', subtitle: 'Jusqu’à 5 employés'),
          _SoftDivider(),
          _PlanRow(
            title: 'Pro',
            subtitle: 'Employés illimités, planning, rapports',
          ),
          _SoftDivider(),
          _PlanRow(
            title: 'Business',
            subtitle: 'Multi-sites, statistiques avancées',
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.circle_grid_hex_fill,
          color: SubscriptionScreen.blue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SubscriptionScreen.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: SubscriptionScreen.subtitle,
                  fontSize: 14,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(icon: icon, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: SubscriptionScreen.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: SubscriptionScreen.subtitle,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.65)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});

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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: Color(0xFFE5E7EB)),
    );
  }
}
