import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'search_by_child_sheet.dart';

// Three entry points into Search's guided flows — lives on Home now (in
// place of a plain search bar), since Search itself defaults straight to
// the A-Z browse list.
class GuidedSearchOptions extends StatelessWidget {
  const GuidedSearchOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.child_care,
            label: 'Search by child',
            onTap: () => showSearchByChildSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.checklist_rtl,
            label: 'Guided search',
            onTap: () => context.push('/guided-search'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.sort_by_alpha,
            label: 'Browse A-Z',
            onTap: () => context.go('/search'),
          ),
        ),
      ],
    );
  }
}

class _GuidedOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GuidedOptionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primaryDark),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
