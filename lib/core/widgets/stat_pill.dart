import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rounded pastel pill showing an icon and a number — the Wonder-Weeks-style
/// stat badge, used wherever a handful of counts need a friendlier look than
/// plain text (profile stats, recipe meta).
class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color fill;
  final VoidCallback? onTap;

  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.fill = AppColors.primaryLight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.onBackground),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.onBackground)),
        ],
      ),
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill,
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
    return onTap == null
        ? column
        : InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: column);
  }
}
