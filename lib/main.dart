import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:focus_flow/router.dart';
import 'l10n/app_localizations.dart';
import './providers/auth_provider.dart';
import './providers/task_provider.dart';
import './providers/focus_provider.dart';
import './widgets/auth_wrapper.dart';
import './theme/app_theme.dart';
import './repositories/repository_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize repository provider with SQLite database
  await RepositoryProvider.instance.init();

  runApp(const MyApp());
  doWhenWindowReady(() {
    const initialSize = Size(1280,800);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "Focus Flow";
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => TaskProvider()),
        ChangeNotifierProvider(create: (context) => FocusProvider()),
      ],
      child: AuthWrapper(
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
          locale: const Locale('zh'),
          routerConfig: router(),
        ),
      ),
    );
  }
}
