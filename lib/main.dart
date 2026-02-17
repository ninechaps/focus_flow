import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:focus_flow/router.dart';
import 'l10n/app_localizations.dart';
import './core/api/http_client.dart';
import './core/auth/auth_storage.dart';
import './providers/auth_provider.dart';
import './providers/task_provider.dart';
import './providers/focus_provider.dart';
import './providers/theme_provider.dart';
import './providers/locale_provider.dart';
import './theme/app_theme.dart';
import './repositories/repository_provider.dart';
import './repositories/http/http_auth_repository.dart';
import './services/device_info_service.dart';
import './services/platform_integration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize repository provider with SQLite database
  await RepositoryProvider.instance.init();

  // Initialize HTTP client
  HttpClient.instance.init();

  // Initialize auth dependencies
  final authStorage = AuthStorage();
  final deviceInfoService = DeviceInfoService(storage: authStorage);
  final authRepository = HttpAuthRepository(dio: HttpClient.instance.dio);
  final authProvider = AuthProvider(
    authRepository: authRepository,
    storage: authStorage,
    deviceInfo: deviceInfoService,
  );

  // Create Provider instances upfront so PlatformIntegrationService can reference them
  final focusProvider = FocusProvider();
  final taskProvider = TaskProvider();

  // Create the platform integration service (tray, hotkeys, notifications)
  final platformService = PlatformIntegrationService(
    focusProvider: focusProvider,
    taskProvider: taskProvider,
  );

  runApp(MyApp(
    authProvider: authProvider,
    focusProvider: focusProvider,
    taskProvider: taskProvider,
    platformService: platformService,
  ));

  doWhenWindowReady(() {
    const initialSize = Size(1280, 800);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "Focus Flow";
    appWindow.show();
  });
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  final FocusProvider focusProvider;
  final TaskProvider taskProvider;
  final PlatformIntegrationService platformService;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.focusProvider,
    required this.taskProvider,
    required this.platformService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = router(authProvider: widget.authProvider);

  @override
  void initState() {
    super.initState();
    // Provide router to platform service for focus page navigation from tray
    widget.platformService.setRouter(_router);
    // Initialize platform services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.platformService.init();
      } catch (e) {
        debugPrint('Platform integration init failed: $e');
      }
    });
  }

  /// Update platform service localized strings when locale changes
  void _updatePlatformStrings(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    widget.platformService.updateLocalizedStrings(PlatformLocalizedStrings(
      trayStartFocus: l10n.trayStartFocus,
      trayStart: l10n.trayStart,
      trayPause: l10n.trayPause,
      trayResume: l10n.trayResume,
      traySkipBreak: l10n.traySkipBreak,
      trayStop: l10n.trayStop,
      trayOpenApp: l10n.trayOpenApp,
      trayQuit: l10n.trayQuit,
      notificationFocusComplete: l10n.notificationFocusComplete,
      notificationFocusBody: (taskName, duration) =>
          l10n.notificationFocusBody(taskName, duration),
      notificationBreakComplete: l10n.notificationBreakComplete,
      notificationBreakBody: l10n.notificationBreakBody,
      popoverFocusSession: l10n.popoverFocusSession,
      popoverPause: l10n.popoverPause,
      popoverStop: l10n.popoverStop,
      popoverResume: l10n.popoverResume,
      popoverStart: l10n.popoverStart,
      popoverThisSession: l10n.popoverThisSession,
      popoverTotalFocus: l10n.popoverTotalFocus,
      popoverSessions: l10n.popoverSessions,
      popoverNoActiveFocus: l10n.popoverNoActiveFocus,
      popoverOpenApp: l10n.popoverOpenApp,
      popoverFocusing: l10n.popoverFocusing,
      popoverPaused: l10n.popoverPaused,
      popoverReady: l10n.popoverReady,
      popoverCompleted: l10n.popoverCompleted,
    ));
  }

  @override
  void dispose() {
    widget.platformService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider.value(value: widget.taskProvider),
        ChangeNotifierProvider.value(value: widget.focusProvider),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('zh'),
            ],
            theme: AppTheme.buildTheme(),
            darkTheme: AppTheme.buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            routerConfig: _router,
            builder: (context, child) {
              _updatePlatformStrings(context);
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
