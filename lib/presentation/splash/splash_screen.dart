import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

// Shown in place by AppShell while auth is resolving — not a routed page,
// so there's no Navigator transition involved. Pure loading UI, no
// navigation logic.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // White backdrop card, same fix as the Home header — the logo's
            // wordmark/icon colors don't read well directly against a
            // saturated background. The logo image already is the full
            // "Bitty Bellies" wordmark lockup, so there's no separate app
            // name text alongside it.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Image.asset('assets/logos/logo-long.png', height: 64, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
