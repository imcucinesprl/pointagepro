import 'package:flutter/cupertino.dart';

import '../core/theme/app_colors.dart';
import 'employee/employee_home_screen.dart';
import 'manager/manager_dashboard_screen.dart';

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,
      tabBar: CupertinoTabBar(
        activeColor: AppColors.primary,
        inactiveColor: AppColors.subtitle,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_crop_circle),
            label: 'Employé',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Manager',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        if (index == 0) {
          return const EmployeeHomeScreen();
        }

        return const ManagerDashboardScreen();
      },
    );
  }
}
