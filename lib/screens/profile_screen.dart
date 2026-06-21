import 'package:flutter/cupertino.dart';

import '../core/services/session_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/ios_card.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String firstName = '';
  String lastName = '';
  String companyName = '';
  String role = '';

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
    });
  }

  Future<void> logout() async {
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
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profil'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 24),

            IosCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    fullName.isEmpty ? 'Utilisateur' : fullName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            CupertinoButton(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(18),
              onPressed: logout,
              child: const Text(
                'Déconnexion',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}