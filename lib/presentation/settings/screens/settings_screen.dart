import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _Section(title: 'Account', tiles: [
            _Tile(icon: Icons.person_outline, label: 'Edit profile', onTap: () => context.push('/profile')),
            _Tile(icon: Icons.lock_outline, label: 'Change password', onTap: () => context.push('/forgot-password')),
          ]),
          _Section(title: 'About', tiles: [
            _Tile(icon: Icons.info_outline, label: 'App version', trailing: '1.0.0', onTap: () {}),
            _Tile(icon: Icons.child_care, label: 'Safety information', onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Safety Information'),
                  content: Text(AppConstants.safetyDisclaimer),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              );
            }),
            _Tile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () {}),
            _Tile(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () {}),
          ]),
          _Section(title: 'Community', tiles: [
            _Tile(icon: Icons.flag_outlined, label: 'How reporting works', onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Reporting'),
                  content: const Text('Use the flag icon on any recipe, comment, or question to report it. Our moderation team reviews all reports and takes action to keep the community safe.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                ),
              );
            }),
            _Tile(icon: Icons.email_outlined, label: 'Contact us', onTap: () {}),
          ]),
          // Monetization placeholder — no UI yet
          // Section('Premium features') — future
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> tiles;
  const _Section({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
        ),
        ...tiles,
        const Divider(height: 1),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: trailing != null
            ? Text(trailing!, style: Theme.of(context).textTheme.bodySmall)
            : const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      );
}
