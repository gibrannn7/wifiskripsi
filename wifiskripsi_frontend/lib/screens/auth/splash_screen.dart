import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/core/constants/app_assets.dart';
import 'package:wifiskripsi_frontend/screens/auth/login_screen.dart';
import 'package:wifiskripsi_frontend/screens/dashboard/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Memberikan jeda singkat untuk menampilkan efek splash screen
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Jika token ada, arahkan ke HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Gerbang Proteksi: Token tidak ada/tidak valid, wajib ke layar masuk (Login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.nightDark,
      body: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(seconds: 1),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Image.asset(
                AppAssets.logo,
                width: 150,
              ),
            );
          },
        ),
      ),
    );
  }
}
