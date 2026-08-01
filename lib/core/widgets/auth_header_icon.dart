import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small rounded icon badge shown above auth-screen headlines — the same
/// Wonder-Weeks-style icon-in-a-pastel-square accent used on the splash
/// screen, instead of a bare text-only header.
class AuthHeaderIcon extends StatelessWidget {
  final IconData icon;
  const AuthHeaderIcon(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
      child: Icon(icon, size: 32, color: AppColors.primaryDark),
    );
  }
}
