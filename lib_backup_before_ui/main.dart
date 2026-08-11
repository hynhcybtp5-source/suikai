import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const SuikaiApp());
}

class SuikaiApp extends StatelessWidget {
  const SuikaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suikai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: SuikaiRoutes.home,
      routes: SuikaiRoutes.routes,
      onGenerateRoute: SuikaiRoutes.onGenerateRoute,
    );
  }
}
