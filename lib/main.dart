import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'services/suikai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SuikaiService.initialize();
  await InteractionStore.restore();
  await localeController.load();
  runApp(const SuikaiApp());
}

class SuikaiApp extends StatelessWidget {
  const SuikaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => MaterialApp(
        title: 'Suikai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: localeController.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        initialRoute: SuikaiRoutes.home,
        routes: SuikaiRoutes.routes,
        onGenerateRoute: SuikaiRoutes.onGenerateRoute,
      ),
    );
  }
}

class ShanMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const ShanMaterialLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'shn';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('th'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}

class ShanWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const ShanWidgetsLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'shn';
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('th'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<WidgetsLocalizations> old,
  ) => false;
}

class ShanCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const ShanCupertinoLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'shn';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('th'));
  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) => false;
}
