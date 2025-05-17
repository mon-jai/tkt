import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatusAndNavigate();
  }

  Future<void> _checkLoginStatusAndNavigate() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;

        if (authService.isLoggedIn) {
          debugPrint("SplashScreen: User is logged in. Navigating to Dashboard Screen.");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          debugPrint("SplashScreen: User is NOT logged in. Navigating to Login Screen.");
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.restaurant_menu, size: 120, color: Colors.white70);
              },
            ),
            const SizedBox(height: 24),
            Text(
              '台科通',
              style: textTheme.titleLarge?.copyWith(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              '你的校園好幫手',
              style: textTheme.bodyMedium?.copyWith(fontSize: 18, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '載入中...',
              style: textTheme.bodySmall?.copyWith(color: const Color.fromARGB(179, 0, 0, 0)),
            ),
          ],
        ),
      ),
    );
  }
}

