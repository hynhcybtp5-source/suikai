import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme/app_theme.dart';

void main() => runApp(const SuikaiApp());

class SuikaiApp extends StatelessWidget {
  const SuikaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suikai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
