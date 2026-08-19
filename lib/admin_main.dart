import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_dashboard.dart';
import 'l10n/app_localizations.dart';
import 'services/suikai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SuikaiService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Admin startup initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(const _AdminStartupErrorApp());
    return;
  }
  runApp(const SuikaiAdminWebApp());
}

class _AdminStartupErrorApp extends StatelessWidget {
  const _AdminStartupErrorApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'ไม่สามารถเริ่มระบบ Admin ได้ กรุณาตรวจสอบ SUPABASE_URL และ SUPABASE_PUBLISHABLE_KEY',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
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
