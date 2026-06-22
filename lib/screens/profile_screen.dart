import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/services/session_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color blue = Color(0xFF0A84FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color text = Color(0xFF111827);
  static const Color subtitle = Color(0xFF6B7280);
  static const Color background = Color(0xFFF3F6FB);

  String firstName = '';
  String lastName = '';
  String companyName = '';
  String role = '';
  String managerName = '';

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> loadSession() async {
    final f = await SessionService.getFirstName();
    final l = await SessionService.getLastName();
    final c = await SessionService.getCompanyName();
    final r = await SessionService.getRole();

    if (!mounted) return;

    setState(() {
      firstName = f;
      lastName = l;
      companyName = c;
      role = r ?? '';

      managerName = f ?? '';
    });
  }

  String get roleLabel {
    return switch (role) {
      'super_admin' => 'Super administrateur',
      'platform_admin' => 'Plateforme',
      'admin' => 'Administrateur',
      'manager' => 'Manager',
      'student' => 'Étudiant',
      'flexi' => 'Flexi',
      'employee' => 'Employé',
      _ => role.isEmpty ? 'Utilisateur' : role,
    };
  }

  Future<void> logout() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Déconnexion'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SessionService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '$firstName $lastName'.trim();

    return CupertinoPageScaffold(
      backgroundColor: background,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xCCF3F6FB),
        border: null,
        middle: Text(
          'Profil',
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
                _ProfileHeroCard(
                  fullName: fullName.isEmpty ? 'Utilisateur' : fullName,
                  companyName: companyName,
                  roleLabel: roleLabel,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        color: blue,
                        title: 'Compte',
                        value: roleLabel,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        icon: CupertinoIcons.building_2_fill,
                        color: purple,
                        title: 'Entreprise',
                        value: companyName.isEmpty ? '--' : companyName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _ProfileRow(
                        icon: CupertinoIcons.person_fill,
                        color: blue,
                        title: 'Prénom',
                        value: firstName.isEmpty ? '--' : firstName,
                      ),
                      const _SoftDivider(),
                      _ProfileRow(
                        icon: CupertinoIcons.person_2_fill,
                        color: purple,
                        title: 'Nom',
                        value: lastName.isEmpty ? '--' : lastName,
                      ),
                      const _SoftDivider(),
                      _ProfileRow(
                        icon: CupertinoIcons.tag_fill,
                        color: green,
                        title: 'Rôle',
                        value: roleLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: logout,
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: red,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: red.withOpacity(0.24),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_right,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Déconnexion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.fullName,
    required this.companyName,
    required this.roleLabel,
  });

  final String fullName;
  final String companyName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final initials = fullName
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e.characters.first.toUpperCase())
        .join();

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
        children: [
          Container(
            height: 92,
            width: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.34),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'U' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            companyName.isEmpty ? 'PointagePro' : companyName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _StatusPill(
            label: roleLabel,
            color: Colors.white,
            textColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.20),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: SizedBox(
        height: 116,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconBubble(icon: icon, color: color),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: _ProfileScreenState.subtitle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ProfileScreenState.text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
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
              color: _ProfileScreenState.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileScreenState.subtitle,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
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

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

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