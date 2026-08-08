import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/views/customer_list_page.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() =>
      _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(
        const Duration(seconds: 2));

    final loggedIn =
    await AuthService.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration:
        const Duration(milliseconds: 420),

        pageBuilder: (context, animation,
            secondaryAnimation) {
          return loggedIn
              ? const CustomerListPage()
              : const LoginPage();
        },

        transitionsBuilder: (context, animation,
            secondaryAnimation, child) {
          // Fade animation
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          // Scale animation
          final scale = Tween<double>(
            begin: 0.92,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
          );

          // Slight upward movement
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold
                        .withValues(alpha: 0.22),
                    AppTheme.surface,
                  ],
                ),
                border: Border.all(
                  color: AppTheme.gold,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '🔑',
                  style: TextStyle(fontSize: 62),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Key Gallery KYC',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Loading your secure local records...',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 30),

            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}