import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Check server health and preload data in background
    final provider = context.read<AppProvider>();
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      provider.checkServerHealth(),
      provider.tryAutoLogin(),
    ]);

    if (mounted) {
      if (provider.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Image.asset(
              'assets/images/cropcure_logo.png',
              height: 180,
              fit: BoxFit.contain,
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end:   const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 900.ms,
                )
                .fadeIn(duration: 600.ms),
          ),
        ),
      ),
    );
  }
}
