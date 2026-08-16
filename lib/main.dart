import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/locale_controller.dart';
import 'core/app_route_observer.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase_repositories.dart';
import 'features/home/home_page.dart';
import 'services/suikai_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _completeTelegramCallback(Uri uri) async {
  if (uri.scheme != 'suikai' && !kIsWeb) return;
  if (uri.queryParameters['code'] == null &&
      uri.queryParameters['error'] == null) {
    return;
  }
  try {
    await (SuikaiService.auth as SupabaseAuthRepository).completeTelegramLogin(
      uri,
    );
    if (SuikaiService.hasValidSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          SuikaiRoutes.home,
          (_) => false,
        );
      });
    }
  } catch (error, stackTrace) {
    debugPrint('Telegram app-link callback failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAIN 1 start');
  await SuikaiService.initialize();
  // Telegram redirects to the app root, which normally builds HomePage rather
  // than LoginPage. Consume the OAuth callback before building routes so the
  // token_hash is exchanged for a persisted Supabase session on every return.
  if (kIsWeb &&
      (Uri.base.queryParameters['code'] != null ||
          Uri.base.queryParameters['error'] != null)) {
    try {
      await SuikaiService.auth.completeTelegramWebLogin();
    } catch (error, stackTrace) {
      debugPrint('Telegram startup callback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  if (!kIsWeb) {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) await _completeTelegramCallback(initialLink);
    appLinks.uriLinkStream.listen(
      _completeTelegramCallback,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Telegram app-link stream failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }
  debugPrint('MAIN 2 service initialized');
  debugPrint('MAIN 3 before runApp');
  runApp(const SuikaiApp());
  final sharedProductId = kIsWeb ? Uri.base.queryParameters['product'] : null;
  if (sharedProductId != null && sharedProductId.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamed(
        SuikaiRoutes.productDetail,
        arguments: sharedProductId,
      );
    });
  }
  debugPrint('MAIN 4 runApp called');
}

class SuikaiApp extends StatelessWidget {
  const SuikaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) => MaterialApp(
        title: 'Suikai',
        navigatorKey: _navigatorKey,
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
        navigatorObservers: [appRouteObserver],
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
