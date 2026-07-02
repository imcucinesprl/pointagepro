import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/services/session_service.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'fullscreen_qr_screen.dart';
import '../../core/services/pointage_service.dart';

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  int? companyId;
  String companyName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

Future<void> loadData() async {
  final result = await PointageService.me();

  if (result["success"] == true) {
    final apiCompany = result["company"];

    if (apiCompany != null) {
      final newCompanyId = int.tryParse(apiCompany["id"].toString()) ?? 0;
      final newCompanyName = apiCompany["name"]?.toString() ?? '';

      await SessionService.saveCompanyId(newCompanyId);
      await SessionService.saveCompanyName(newCompanyName);

      if (!mounted) return;

      setState(() {
        companyId = newCompanyId;
        companyName = newCompanyName;
        isLoading = false;
      });

      return;
    }
  }

  final id = await SessionService.getCompanyId();
  final name = await SessionService.getCompanyName();

  if (!mounted) return;

  setState(() {
    companyId = id;
    companyName = name;
    isLoading = false;
  });
}

  String get qrUrl {
    return 'https://taskflowapp.eu/pointagepro/qr_generator.php?company_id=$companyId&mobile=1';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Code QR Pointage'),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : companyId == null
            ? const Center(child: Text('Entreprise introuvable'))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _HeroCard(),

                  const SizedBox(height: 18),

                  _GlassCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 54,
                              width: 54,
                              decoration: BoxDecoration(
                                color: blue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                CupertinoIcons.building_2_fill,
                                color: blue,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    companyName.isEmpty
                                        ? 'Votre entreprise'
                                        : companyName,
                                    style: const TextStyle(
                                      color: text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'ID entreprise : $companyId',
                                    style: const TextStyle(
                                      color: subtitle,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        Container(
                          width: double.infinity,
                          height: 430,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: blue.withOpacity(0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: blue.withOpacity(0.12),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: WebViewWidget(
                                  controller: WebViewController()
                                    ..setJavaScriptMode(
                                      JavaScriptMode.unrestricted,
                                    )
                                    ..loadRequest(Uri.parse(qrUrl)),
                                ),
                              ),

                              Positioned.fill(
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        fullscreenDialog: true,
                                        builder: (_) => FullScreenQrScreen(
                                          qrUrl: qrUrl,
                                          companyName: companyName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    color: CupertinoColors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                CupertinoIcons.info_circle_fill,
                                color: blue,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Affichez ce code dans un endroit visible pour permettre aux employés de pointer.',
                                  style: TextStyle(
                                    color: subtitle,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.qrcode,
                          title: 'QR actif',
                          subtitle: 'Entreprise',
                          color: blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.checkmark_shield_fill,
                          title: 'Sécurisé',
                          subtitle: 'Pointage',
                          color: green,
                        ),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_QrCodeScreenState.blue, _QrCodeScreenState.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _QrCodeScreenState.blue.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -60,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  CupertinoIcons.qrcode,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const Spacer(),
              const Text(
                'PointagePro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Code QR de votre entreprise',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.86),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _QrCodeScreenState.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _QrCodeScreenState.subtitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
