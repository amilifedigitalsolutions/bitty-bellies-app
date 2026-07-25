import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

// The router redirect (RouterNotifier) handles splash → home transition as soon
// as auth resolves. This screen is a pure loading UI with no navigation logic.
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('🥦', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 8),
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
