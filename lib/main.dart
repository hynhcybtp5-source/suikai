import 'package:app_links/app_links.dart';
import 'package:camera_android/camera_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'l10n/mobile_localizations.dart';
import 'core/locale_controller.dart';
import 'core/app_route_observer.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase_repositories.dart';
import 'features/home/home_page.dart';
import 'services/suikai_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _telegramLoginLoading = ValueNotifier(false);
bool _telegramCallbackInProgress = false;

Future<void> _completeTelegramCallback(Uri uri) async {
  if (uri.scheme != 'suikai' && !kIsWeb) return;
  debugPrint(
    'CALLBACK RECEIVED hasCode=${uri.queryParameters['code']?.isNotEmpty == true} '
    'hasError=${uri.queryParameters['error']?.isNotEmpty == true}',
  );
  if (uri.queryParameters['code'] == null &&
      uri.queryParameters['error'] == null) {
    return;
  }
  if (_telegramCallbackInProgress) return;
  _telegramCallbackInProgress = true;
  _telegramLoginLoading.value = true;
  try {
    await (SuikaiService.auth as SupabaseAuthRepository).completeTelegramLogin(
      uri,
    );
    debugPrint(
      'CALLBACK COMPLETE sessionNull=${SuikaiService.currentSession == null} '
      'currentUserNull=${SuikaiService.currentUserId == null}',
    );
    if (SuikaiService.hasValidSession) {
      debugPrint('PROFILE LOAD START provider=telegram');
      await SuikaiService.currentProfile();
      debugPrint('PROFILE LOAD SUCCESS provider=telegram');
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
  } finally {
    _telegramLoginLoading.value = false;
    _telegramCallbackInProgress = false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Camera2 reports both physical lenses on affected MediaTek devices where
  // the default CameraX implementation only exposes the rear camera.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    AndroidCamera.registerWith();
  }
  debugPrint('MAIN 1 start');
  try {
    await SuikaiService.initialize();
  } catch (error, stackTrace) {
    debugPrint('Suikai startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(const _StartupErrorApp());
    return;
  }
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

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.orange),
                SizedBox(height: 18),
                Text(
                  'ไม่สามารถเปิด Suikai ได้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'ยังไม่ได้ตั้งค่าการเชื่อมต่อบริการ กรุณาเพิ่ม SUPABASE_URL และ SUPABASE_PUBLISHABLE_KEY ก่อนรันเว็บ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SuikaiApp extends StatelessWidget {
  const SuikaiApp({super.key});

  String get _initialRoute {
    if (!kIsWeb) return SuikaiRoutes.home;
    return Uri.base.queryParameters['screen'] == 'admin' ||
            Uri.base.path == SuikaiRoutes.admin ||
            Uri.base.fragment == SuikaiRoutes.admin
        ? SuikaiRoutes.admin
        : SuikaiRoutes.home;
  }

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
        initialRoute: _initialRoute,
        routes: SuikaiRoutes.routes,
        onGenerateRoute: SuikaiRoutes.onGenerateRoute,
        navigatorObservers: [appRouteObserver],
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: _telegramLoginLoading,
          child: child,
          builder: (context, isLoadingTelegramProfile, child) {
            if (!isLoadingTelegramProfile) {
              return child ?? const SizedBox.shrink();
            }
            final l10n = AppLocalizations.of(context);
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                Positioned.fill(
                  child: AbsorbPointer(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      builder: (context, opacity, _) => Opacity(
                        opacity: opacity,
                        child: ColoredBox(
                          color: AppTheme.surface,
                          child: SafeArea(
                            child: Center(
                              child: Semantics(
                                liveRegion: true,
                                label: l10n.ui('loadingTelegramProfile'),
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.orange,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
