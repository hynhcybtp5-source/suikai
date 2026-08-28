import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:camera_android/camera_android.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'l10n/mobile_localizations.dart';
import 'core/locale_controller.dart';
import 'core/app_route_observer.dart';
import 'core/operation_status.dart';
import 'core/pending_telegram_callback.dart';
import 'core/password_recovery_uri.dart';
import 'core/password_recovery_navigation_guard.dart';
import 'core/theme/app_theme.dart';
import 'data/supabase_repositories.dart';
import 'features/home/home_page.dart';
import 'features/auth/auth_page.dart';
import 'features/startup/network_blocked_screen.dart';
import 'services/suikai_service.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _telegramLoginLoading = ValueNotifier(false);
bool _telegramCallbackInProgress = false;
bool _supabaseReadyForTelegramCallback = false;
final _pendingTelegramCallback = PendingTelegramCallback();
StreamSubscription<Uri>? _telegramAppLinkSubscription;
StreamSubscription<AuthState>? _passwordRecoveryAuthSubscription;
bool _pendingPasswordRecovery = false;
final _resetPasswordNavigationGuard = PasswordRecoveryNavigationGuard();

Future<void> _receiveTelegramCallback(Uri uri) async {
  if (!_pendingTelegramCallback.capture(uri)) return;
  debugPrint(
    'TELEGRAM CALLBACK PENDING hasCode=${uri.queryParameters['code']?.isNotEmpty == true} '
    'hasError=${uri.queryParameters['error']?.isNotEmpty == true}',
  );
  if (_supabaseReadyForTelegramCallback) {
    await _processPendingTelegramCallback();
  }
}

Future<void> _processPendingTelegramCallback() =>
    _pendingTelegramCallback.process(_completeTelegramCallback);

void _startTelegramAppLinkListener() {
  if (kIsWeb || _telegramAppLinkSubscription != null) return;
  final appLinks = AppLinks();
  _telegramAppLinkSubscription = appLinks.uriLinkStream.listen(
    _receiveAppLink,
    onError: (Object error, StackTrace stackTrace) {
      debugPrint('Telegram app-link stream failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
  unawaited(() async {
    try {
      final initialLink = await appLinks.getInitialLink().timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
      if (initialLink != null) await _receiveAppLink(initialLink);
    } catch (error, stackTrace) {
      debugPrint('Telegram initial app-link failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }());
}

Future<void> _receiveAppLink(Uri uri) async {
  if (isPasswordRecoveryUri(uri)) {
    _pendingPasswordRecovery = true;
    debugPrint('PASSWORD RECOVERY DEEP LINK RECEIVED');
    if (_supabaseReadyForTelegramCallback) _openPendingPasswordRecovery();
    return;
  }
  await _receiveTelegramCallback(uri);
}

void _openPendingPasswordRecovery() {
  if (!_pendingPasswordRecovery || !_resetPasswordNavigationGuard.tryOpen()) return;
  _pendingPasswordRecovery = false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _resetPasswordNavigationGuard.close();
      _pendingPasswordRecovery = true;
      return;
    }
    navigator
        .push(MaterialPageRoute<void>(builder: (_) => const ResetPasswordPage()))
        .whenComplete(_resetPasswordNavigationGuard.close);
  });
}

void _startPasswordRecoveryListener() {
  if (_passwordRecoveryAuthSubscription != null) return;
  _passwordRecoveryAuthSubscription = SupabaseBackend
      .client
      .auth
      .onAuthStateChange
      .listen((data) {
        if (data.event != AuthChangeEvent.passwordRecovery) return;
        _pendingPasswordRecovery = true;
        debugPrint('PASSWORD RECOVERY EVENT RECEIVED');
        _openPendingPasswordRecovery();
      });
}

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
  runApp(const _BootstrapApp());
}

Future<void> _initializeApplication(ValueChanged<String> updateStatus) async {
  debugPrint('MAIN 1 start');
  updateStatus('กำลังตรวจสอบการเชื่อมต่อ...');
  await SuikaiService.initialize();
  _supabaseReadyForTelegramCallback = true;
  _startPasswordRecoveryListener();
  updateStatus('กำลังโหลดข้อมูลเริ่มต้น...');
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
    updateStatus('กำลังเตรียมการเข้าสู่ระบบ...');
    await _processPendingTelegramCallback();
    _openPendingPasswordRecovery();
  }
  debugPrint('MAIN 2 service initialized');
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  String _message = 'กำลังเริ่มแอป...';
  Object? _error;
  var _ready = false;
  Timer? _slowConnectionTimer;

  @override
  void initState() {
    super.initState();
    // Start after Flutter has mounted the app, but before the first network
    // probe. Some Android devices do not expose a cold-start intent to
    // app_links until the widget binding has a mounted application.
    _startTelegramAppLinkListener();
    _slowConnectionTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_ready) {
        setState(
          () => _message = 'การเชื่อมต่อใช้เวลานานกว่าปกติ กรุณารอสักครู่',
        );
      }
    });
    _start();
  }

  @override
  void dispose() {
    _slowConnectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (mounted) {
      setState(() {
        _error = null;
        _message = 'กำลังเริ่มแอป...';
      });
    }
    try {
      await _initializeApplication((message) {
        if (mounted) setState(() => _message = message);
      });
      if (!mounted) return;
      setState(() {
        _message = 'กำลังเตรียมหน้าแรก...';
        _ready = true;
      });
      _slowConnectionTimer?.cancel();
      final sharedProductId = kIsWeb
          ? Uri.base.queryParameters['product']
          : null;
      if (sharedProductId != null && sharedProductId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.pushNamed(
            SuikaiRoutes.productDetail,
            arguments: sharedProductId,
          );
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Suikai startup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _error = error);
      _slowConnectionTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const SuikaiApp();
    if (_error != null) {
      return MaterialApp(
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
        home: NetworkBlockedScreen(onRetry: _start),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LoadingStatusView(message: _message),
            ),
          ),
        ),
      ),
    );
  }
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
