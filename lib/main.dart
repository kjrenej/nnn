import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'state/app_state.dart';
import 'auth/auth_service.dart';
import 'router/app_router.dart';
import 'theme/rento_theme.dart';
import 'l10n/localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      
    ),
  );

  // Initialize auth listener & app state
  AuthService.instance.initialize();
  await AppState.instance.initialize();

  runApp(const RentoApp());
}

class RentoApp extends StatelessWidget {
  const RentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppState.instance),
        ChangeNotifierProvider.value(value: AuthService.instance),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp.router(
            title: 'Rento',
            debugShowCheckedModeBanner: false,
            theme: RentoTheme.lightTheme,
            darkTheme: RentoTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(appState.selectedLocale),
            supportedLocales: const [Locale('en'), Locale('hi')],
            localizationsDelegates: [
              RentoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
