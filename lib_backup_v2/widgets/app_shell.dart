import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final String? title;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
    this.title,
    this.actions,
  });

  static const _routes = [
    AppRoutes.home,
    AppRoutes.stores,
    AppRoutes.post,
    AppRoutes.map,
    AppRoutes.account,
  ];

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, _routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!, style: const TextStyle(fontWeight: FontWeight.w700)),
              actions: actions,
            ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _go(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded, color: AppTheme.orange), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded, color: AppTheme.orange), label: 'ร้านค้า'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded, color: AppTheme.orange), label: 'ลงขาย'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded, color: AppTheme.orange), label: 'แผนที่'),
          NavigationDestination(icon: Icon(Icons.menu_rounded), selectedIcon: Icon(Icons.menu_open_rounded, color: AppTheme.orange), label: 'จัดการ'),
        ],
      ),
    );
  }
}
