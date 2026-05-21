import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wifiskripsi_frontend/core/constants/app_colors.dart';
import 'package:wifiskripsi_frontend/providers/auth_provider.dart';
import 'package:wifiskripsi_frontend/providers/dashboard_provider.dart';
import 'package:wifiskripsi_frontend/providers/admin_provider.dart';
import 'package:wifiskripsi_frontend/providers/transaction_provider.dart';
import 'package:wifiskripsi_frontend/providers/notification_provider.dart';
import 'package:wifiskripsi_frontend/screens/auth/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Mendaftarkan semua Provider State secara global di level aplikasi
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Wifiskripsi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.bgCanvas,
          fontFamily: 'Inter',
        ),
        // Gerbang utama langsung diarahkan ke SplashScreen (Strict Access)
        home: const SplashScreen(),
      ),
    );
  }
}