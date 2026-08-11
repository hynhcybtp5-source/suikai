import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_dashboard.dart';
import 'l10n/app_localizations.dart';
import 'services/suikai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuikaiService.initialize();
  runApp(const SuikaiAdminWebApp());
}

class SuikaiAdminWebApp extends StatelessWidget {
  const SuikaiAdminWebApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Suikai Admin',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('th'),
    supportedLocales: const [Locale('th'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: const AdminDashboard(),
  );
}
