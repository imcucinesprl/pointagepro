import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/session_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color red = Color(0xFFFF3B30);
  static const Color purple = Color(0xFF7C3AED);
  static const Color background = Color(0xFFF3F6FB);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);

  String companyName = '';
  String companyStatus = '';
  String subscriptionStatus = '';
  String plan = '';
  String trialEndsAt = '';
  String subscriptionEndsAt = '';
  int companyId = 0;
  int userId = 0;

  static const String renewUrl =
      'https://taskflowapp.eu/pointagepro-web/subscription.php';

  @override
  void initState() {
    super.initState();
    loadSubscription();
  }

  Future<void> loadSubscription() async {
    final c = await SessionService.getCompanyName();
    final cs = await SessionService.getCompanyStatus();
    final ss = await SessionService.getSubscriptionStatus();
    final p = await SessionService.getPlan();
    final trial = await SessionService.getTrialEndsAt();
    final end = await SessionService.getSubscriptionEndsAt();
    final cid = await SessionService.getCompanyId();
    final uid = await SessionService.getUserId();

    if (!mounted) return;

    setState(() {
      companyName = c;
      companyStatus = cs;
      subscriptionStatus = ss;
      plan = p;
      trialEndsAt = trial;
      subscriptionEndsAt = end;
      companyId = cid ?? 0;
      userId = uid ?? 0;
    });
  }

  bool get isActive {
    return subscriptionStatus == 'active' ||
        subscriptionStatus == 'trialing' ||
        subscriptionStatus == 'trial';
  }

  Color get statusColor {
    if (isActive) return green;
    if (companyStatus == 'blocked' || companyStatus == 'inactive') return red;
    return orange;
  }

  String get statusLabel {
    if (subscriptionStatus == 'active') return 'Abonnement actif';
    if (subscriptionStatus == 'trialing' || subscriptionStatus == 'trial') {
      return 'Période d’essai active';
    }
    if (companyStatus == 'blocked') return 'Compte bloqué';
    if (companyStatus == 'inactive') return 'Compte inactif';
    if (subscriptionStatus.isEmpty) return 'Statut non défini';
    return subscriptionStatus;
  }

  String get planLabel {
    if (plan.isEmpty) return 'Non défini';
    return plan[0].toUpperCase() + plan.substring(1);
  }

Future<void> openRenewPage() async {
  final uri = Uri.parse(
    'https://taskflowapp.eu/pointagepro-web/subscription.php'
    '?company_id=$companyId&user_id=$userId',
  );

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Impossible d’ouvrir la page'),
        content: Text('Veuillez réessayer plus tard.'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Abonnement',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        border: null,
        backgroundColor: Color(0xCCF3F6FB),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 34),
          children: [
            Container(
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
                    color: blue.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.creditcard_fill,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'PointagePro Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companyName.isEmpty ? 'Votre entreprise' : companyName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.88),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            _InfoCard(
              icon: CupertinoIcons.checkmark_seal_fill,
              iconColor: statusColor,
              title: 'Statut',
              value: statusLabel,
            ),

            _InfoCard(
              icon: CupertinoIcons.cube_box_fill,
              iconColor: purple,
              title: 'Formule',
              value: planLabel,
            ),

            if (subscriptionEndsAt.isNotEmpty)
              _InfoCard(
                icon: CupertinoIcons.calendar,
                iconColor: blue,
                title: 'Fin d’abonnement',
                value: subscriptionEndsAt,
              ),

            if (trialEndsAt.isNotEmpty)
              _InfoCard(
                icon: CupertinoIcons.time_solid,
                iconColor: orange,
                title: 'Fin de l’essai',
                value: trialEndsAt,
              ),

            const SizedBox(height: 20),

            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: openRenewPage,
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_up_right_square_fill,
                      color: Colors.white,
                      size: 23,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Renouveler l’abonnement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            _BenefitsCard(),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _SubscriptionScreenState.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '--' : value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SubscriptionScreenState.subtitle,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      'Pointage illimité',
      'Gestion des employés',
      'Planning centralisé',
      'Rapports et statistiques',
      'Historique des pointages',
      'Accès web administrateur',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inclus avec PointagePro',
            style: TextStyle(
              color: _SubscriptionScreenState.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...benefits.map(
            (benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: _SubscriptionScreenState.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: _SubscriptionScreenState.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}