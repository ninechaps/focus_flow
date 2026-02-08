import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:focus_flow/router.dart';
import 'l10n/app_localizations.dart';
import './providers/auth_provider.dart';
import './providers/task_provider.dart';
import './providers/focus_provider.dart';
import './providers/theme_provider.dart';
import './widgets/auth_wrapper.dart';
import './theme/app_theme.dart';
import './repositories/repository_provider.dart';
import './services/platform-integration-service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize repository provider with SQLite database
  await RepositoryProvider.instance.init();

  // Create Provider instances upfront so PlatformIntegrationService can reference them
  final focusProvider = FocusProvider();
  final taskProvider = TaskProvider();

  // Create the platform integration service (tray, hotkeys, notifications)
  final platformService = PlatformIntegrationService(
    focusProvider: focusProvider,
    taskProvider: taskProvider,
  );

  runApp(MyApp(
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
  final FocusProvider focusProvider;
  final TaskProvider taskProvider;
  final PlatformIntegrationService platformService;

  const MyApp({
    super.key,
    required this.focusProvider,
    required this.taskProvider,
    required this.platformService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = router();

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

  @override
  void dispose() {
    widget.platformService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider.value(value: widget.taskProvider),
        ChangeNotifierProvider.value(value: widget.focusProvider),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AuthWrapper(
            child: MaterialApp.router(
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
              locale: const Locale('zh'),
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
