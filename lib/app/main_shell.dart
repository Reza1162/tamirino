import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/customers/customers_page.dart';
import '../features/repair_orders/orders_list_page.dart';
import '../features/reports/reports_page.dart';
import '../features/settings/settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    DashboardPage(),
    OrdersListPage(),
    CustomersPage(),
    ReportsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppTheme.primary : Colors.grey,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppTheme.primary), label: 'خانه'),
            NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: AppTheme.primary), label: 'سفارش‌ها'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: AppTheme.primary), label: 'مشتریان'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primary), label: 'گزارش‌ها'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppTheme.primary), label: 'تنظیمات'),
          ],
        ),
      ),
    );
  }
}
