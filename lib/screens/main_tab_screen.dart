import 'package:flutter/cupertino.dart';

import '../core/services/session_service.dart';
import '../core/services/update_service.dart';
import '../core/theme/app_colors.dart';
import '../widgets/update_dialog.dart';

import 'employee/employee_home_screen.dart';
import 'employee/employee_planning_screen.dart';
import 'manager/manager_dashboard_screen.dart';
import 'profile_screen.dart';
import 'admin/qr_code_screen.dart';
import '../widgets/subscription_warning_dialog.dart';
import '../core/services/pointage_service.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  String role = '';
  int? companyId;
  int? userId;
  bool isLoading = true;
  bool _subscriptionPopupShown = false;

  bool get canAccessManager {
    return ['admin', 'super_admin', 'platform_admin'].contains(role);
  }

  bool get canAccessQrCode {
    return ['admin', 'super_admin', 'platform_admin'].contains(role);
  }

  bool get canAccessPlanning {
    return [
      'employee',
      'student',
      'flexi',
      'admin',
      'super_admin',
      'platform_admin',
    ].contains(role);
  }

  @override
  void initState() {
    super.initState();
    loadSession();

    Future.delayed(const Duration(milliseconds: 800), checkForUpdates);
  }

  Future<void> loadSession() async {
    final savedRole = await SessionService.getRole();
    final savedCompanyId = await SessionService.getCompanyId();
    final savedUserId = await SessionService.getUserId();

    if (!mounted) return;

    setState(() {
      role = savedRole ?? '';
      companyId = savedCompanyId;
      userId = savedUserId;
      isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSubscriptionWarning();
    });
  }

  Future<void> checkForUpdates() async {
    final data = await UpdateService.check();

    if (data == null || !mounted) {
      return;
    }

    final current = data['current_version']?.toString() ?? '';
    final minimum = data['minimum_version']?.toString() ?? '';
    final latest = data['latest_version']?.toString() ?? '';

    if (current.isEmpty || minimum.isEmpty || latest.isEmpty) {
      return;
    }

    final forceUpdate = UpdateService.isVersionLower(current, minimum);

    final updateAvailable = UpdateService.isVersionLower(current, latest);

    if (forceUpdate || updateAvailable) {
      await UpdateDialog.show(context, data, forceUpdate);
    }
  }

  Future<void> _showSubscriptionWarning() async {
    if (_subscriptionPopupShown) {
      print("POPUP SUB: déjà affichée");
      return;
    }

    print("POPUP SUB: vérification démarrée");

    final data = await PointageService.me();

    print("POPUP SUB DATA: ${data["subscription"]}");

    if (!mounted) return;

    final showPopup = data["subscription"]?["show_popup"] == true;

    print("POPUP SUB showPopup = $showPopup");

    if (!showPopup) return;

    _subscriptionPopupShown = true;

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    print("POPUP SUB: affichage");

    await SubscriptionWarningDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    final items = <BottomNavigationBarItem>[
      if (canAccessManager)
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chart_bar_alt_fill),
          activeIcon: Icon(CupertinoIcons.chart_bar_alt_fill),
          label: 'Manager',
        ),

      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.time),
        activeIcon: Icon(CupertinoIcons.time_solid),
        label: 'Pointage',
      ),

      if (canAccessQrCode)
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.qrcode),
          activeIcon: Icon(CupertinoIcons.qrcode_viewfinder),
          label: 'QR',
        ),

      if (canAccessPlanning)
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.calendar),
          activeIcon: Icon(CupertinoIcons.calendar_today),
          label: 'Planning',
        ),

      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        activeIcon: Icon(CupertinoIcons.person_fill),
        label: 'Profil',
      ),
    ];

    final screens = <Widget>[
      if (canAccessManager) const ManagerDashboardScreen(),

      const EmployeeHomeScreen(),

      if (canAccessQrCode) const QrCodeScreen(),

      if (canAccessPlanning)
        companyId != null && userId != null
            ? EmployeePlanningScreen(companyId: companyId!, userId: userId!)
            : const _SessionIncompleteScreen(),

      const ProfileScreen(),
    ];

    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.88),
        activeColor: AppColors.primary,
        inactiveColor: AppColors.subtitle,
        border: Border(
          top: BorderSide(
            color: AppColors.softBorder.withOpacity(0.65),
            width: 0.6,
          ),
        ),
        iconSize: 24,
        height: 62,
        items: items,
      ),
      tabBuilder: (context, index) {
        return screens[index];
      },
    );
  }
}

class _SessionIncompleteScreen extends StatelessWidget {
  const _SessionIncompleteScreen();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(middle: Text('Planning')),
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: AppColors.danger,
                  size: 42,
                ),
                SizedBox(height: 14),
                Text(
                  'Session incomplète',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Impossible de récupérer les informations utilisateur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.subtitle, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
