import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/pointage_service.dart';

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
  String subscriptionEndsAtLabel = '';
  String trialEndsAtLabel = '';
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
    final data = await PointageService.me();

    if (!mounted) return;

    final company = data["company"];
    final subscription = data["subscription"];

    setState(() {
      companyName = company?["name"]?.toString() ?? '';
      companyStatus = company?["status"]?.toString() ?? '';
      subscriptionStatus = subscription?["status"]?.toString() ?? '';
      plan = subscription?["plan_key"]?.toString() ?? '';
trialEndsAt = subscription?["trial_ends_at"]?.toString() ?? '';
subscriptionEndsAt =
    subscription?["subscription_ends_at"]?.toString() ?? '';

trialEndsAtLabel = formatDateFr(trialEndsAt);
subscriptionEndsAtLabel = formatDateFr(subscriptionEndsAt);
      companyId = int.tryParse(company?["id"]?.toString() ?? '') ?? 0;
      userId = int.tryParse(data["user"]?["id"]?.toString() ?? '') ?? 0;
    });
  }

  bool get isActive {
    final hasValidStatus =
        subscriptionStatus == 'active' ||
        subscriptionStatus == 'trialing' ||
        subscriptionStatus == 'trial';

    if (!hasValidStatus) return false;

    if (subscriptionEndsAt.isNotEmpty) {
      final endDate = DateTime.tryParse(subscriptionEndsAt);

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        return false;
      }
    }

    return true;
  }

  Color get statusColor {
    if (subscriptionEndsAt.isNotEmpty) {
      final endDate = DateTime.tryParse(subscriptionEndsAt);

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        return red;
      }
    }

    switch (subscriptionStatus) {
      case 'active':
        return green;

      case 'trial':
      case 'trialing':
        return blue;

      case 'past_due':
        return orange;

      case 'canceled':
      case 'cancelled':
      case 'expired':
        return red;

      default:
        return orange;
    }
  }

  String get statusLabel {
    if (subscriptionEndsAt.isNotEmpty) {
      final endDate = DateTime.tryParse(subscriptionEndsAt);

      if (endDate != null && endDate.isBefore(DateTime.now())) {
        return 'Abonnement expiré';
      }
    }

    switch (subscriptionStatus) {
      case 'active':
        return 'Abonnement actif';

      case 'trial':
      case 'trialing':
        return 'Période d’essai';

      case 'past_due':
        return 'Paiement en attente';

      case 'canceled':
      case 'cancelled':
        return 'Abonnement annulé';

      case 'expired':
        return 'Abonnement expiré';

      default:
        break;
    }

    if (companyStatus == 'blocked') {
      return 'Entreprise bloquée';
    }

    if (companyStatus == 'inactive') {
      return 'Entreprise inactive';
    }

    return 'Aucun abonnement';
  }

  String get planLabel {
    if (plan.isEmpty) return 'Non défini';
    return plan[0].toUpperCase() + plan.substring(1);
  }

  String formatDateFr(String value) {
  if (value.trim().isEmpty) return '';

  final date = DateTime.tryParse(value);
  if (date == null) return value;

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day/$month/$year';
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
                value: subscriptionEndsAtLabel,
              ),

            if (trialEndsAt.isNotEmpty)
              _InfoCard(
                icon: CupertinoIcons.time_solid,
                iconColor: orange,
                title: 'Fin de l’essai',
                value: trialEndsAtLabel,
              ),

            const SizedBox(height: 20),

            const SizedBox(height: 8),

            _PlansCard(currentPlan: plan),

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

class _PlansCard extends StatelessWidget {
  const _PlansCard({required this.currentPlan});

  final String currentPlan;

  @override
  Widget build(BuildContext context) {
    final plans = [
      {
        'key': 'free',
        'name': 'Free',
        'price': '0 € / mois',
        'description': 'Idéal pour tester PointagePro.',
        'features': [
          'Essai ou accès limité',
          'Pointage de base',
          'Gestion simple des employés',
        ],
      },
      {
        'key': 'pro',
        'name': 'Pro',
        'price': '19,99 € / mois',
        'description': 'Pour les petites équipes.',
        'features': [
          'Pointage illimité',
          'QR Code entreprise',
          'Planning',
          'Historique des pointages',
        ],
      },
      {
        'key': 'business',
        'name': 'Business',
        'price': '39,99 € / mois',
        'description': 'Pour les entreprises avec plusieurs employés.',
        'features': [
          'Toutes les fonctions Pro',
          'Rapports avancés',
          'Statistiques',
          'Accès web administrateur',
          'Support prioritaire',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Formules disponibles',
          style: TextStyle(
            color: _SubscriptionScreenState.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        ...plans.map((planData) {
          final isCurrent = currentPlan == planData['key'];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isCurrent
                    ? _SubscriptionScreenState.blue
                    : Colors.transparent,
                width: 2,
              ),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        planData['name'] as String,
                        style: const TextStyle(
                          color: _SubscriptionScreenState.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _SubscriptionScreenState.blue.withOpacity(
                            0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Actuel',
                          style: TextStyle(
                            color: _SubscriptionScreenState.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  planData['price'] as String,
                  style: const TextStyle(
                    color: _SubscriptionScreenState.blue,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  planData['description'] as String,
                  style: const TextStyle(
                    color: _SubscriptionScreenState.subtitle,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...(planData['features'] as List<String>).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: _SubscriptionScreenState.green,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: _SubscriptionScreenState.text,
                              fontSize: 14,
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
        }),
      ],
    );
  }
}
