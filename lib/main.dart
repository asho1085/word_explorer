import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration with safe fallback
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[Env] Notice: .env file not found or failed to load: $e. Using default test ad IDs.');
  }

  // Initialize local mobile database (SharedPreferences)
  await DatabaseService.instance.init();

  // Initialize Google Mobile Ads SDK (reads IDs from .env or defaults to test IDs)
  await AdService.instance.initialize();

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
          title: 'Word Search Explorer',
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
