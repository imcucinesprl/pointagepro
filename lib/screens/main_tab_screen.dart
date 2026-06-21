import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/services/session_service.dart';
import '../core/theme/app_colors.dart';
import 'employee/employee_home_screen.dart';
import 'employee/employee_planning_screen.dart';
import 'manager/manager_dashboard_screen.dart';
import 'profile_screen.dart';

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

  bool get canAccessManager {
    return [
      'admin',
      'super_admin',
      'platform_admin',
    ].contains(role);
  }

  bool get isEmployeeOnly {
    return [
      'employee',
      'student',
      'flexi',
    ].contains(role);
  }

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> loadSession() async {
    final savedRole = await SessionService.getRole();
    final savedCompanyId = await SessionService.getCompanyId();
    final savedUserId = await SessionService.getUserId();

print("ROLE: $savedRole");
print("COMPANY ID: $savedCompanyId");
print("USER ID: $savedUserId");

    if (!mounted) return;

    setState(() {
      role = savedRole ?? '';
      companyId = savedCompanyId;
      userId = savedUserId;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: AppColors.background,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person_crop_circle),
        label: 'Employé',
      ),
if (isEmployeeOnly)
  const BottomNavigationBarItem(
    icon: Icon(CupertinoIcons.calendar),
    label: 'Planning',
  ),
      if (canAccessManager)
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chart_bar_alt_fill),
          label: 'Manager',
        ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person_fill),
        label: 'Profil',
      ),
    ];

    final screens = <Widget>[
      const EmployeeHomeScreen(),
if (isEmployeeOnly)
  companyId != null && userId != null
      ? EmployeePlanningScreen(
          companyId: companyId!,
          userId: userId!,
        )
      : const CupertinoPageScaffold(
          backgroundColor: AppColors.background,
          child: Center(
            child: Text("Session incomplète"),
          ),
        ),
      if (canAccessManager) const ManagerDashboardScreen(),
      const ProfileScreen(),
    ];

    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,
      tabBar: CupertinoTabBar(
        activeColor: AppColors.primary,
        inactiveColor: AppColors.subtitle,
        items: items,
      ),
      tabBuilder: (context, index) {
        return screens[index];
      },
    );
  }
}