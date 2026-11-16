import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any unhandled Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };

  try {
    // Initialize local mobile database (SharedPreferences)
    await DatabaseService.instance.init();
    // Initialize Firebase Authentication (falls back to offline mode on failure)
    await AuthService.instance.initializeFirebase();
    // Initialize authentication session
    await AuthService.instance.init();
  } catch (e, stack) {
    debugPrint('[main] DatabaseService / AuthService init error: $e\n$stack');
  }

  try {
    // Initialize AdService (ad-free mode for this release)
    await AdService.instance.initialize();
  } catch (e, stack) {
    debugPrint('[main] AdService init error: $e\n$stack');
  }

  runApp(const WordSearchExplorerApp());
}

class WordSearchExplorerApp extends StatelessWidget {
  const WordSearchExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DatabaseService.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          navigatorKey: AdService.navigatorKey,
          title: 'Shabdkhoj: Word Search Puzzle',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightThemeData,
          darkTheme: AppTheme.darkThemeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
