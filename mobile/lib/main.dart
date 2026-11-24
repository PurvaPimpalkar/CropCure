import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';
import 'screens/treatment_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  AppTheme.configure(isDarkMode);

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor:           Colors.transparent,
      statusBarIconBrightness:  isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );

  runApp(CropCureApp(initialDarkMode: isDarkMode));
}

class CropCureApp extends StatelessWidget {
  final bool initialDarkMode;
  const CropCureApp({super.key, required this.initialDarkMode});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initTheme(initialDarkMode)..tryAutoLogin()..checkServerHealth(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor:           Colors.transparent,
              statusBarIconBrightness:  provider.isDarkMode ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: AppTheme.background,
              systemNavigationBarIconBrightness: provider.isDarkMode ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title:          'CropCure',
            debugShowCheckedModeBanner: false,
            theme:          AppTheme.getTheme(provider.isDarkMode),
            initialRoute:   '/',
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _fade(const SplashScreen());
      case '/login':
        return _fade(const LoginScreen());
      case '/signup':
        return _slide(const SignupScreen());
      case '/home':
        return _slide(const HomeScreen());
      case '/scan':
        return _slide(const ScanScreen());
      case '/result':
        return _slide(const ResultScreen());
      case '/treatment':
        return _slide(const TreatmentScreen());
      case '/library':
        return _slide(const LibraryScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRoute _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );

  static PageRoute _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      const begin = Offset(1.0, 0.0);
      const end   = Offset.zero;
      final tween = Tween(begin: begin, end: end)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: anim.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
