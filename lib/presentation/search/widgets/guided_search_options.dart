import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'search_by_child_sheet.dart';

// Three entry points into Search's guided flows — lives on Home now (in
// place of a plain search bar), since Search itself defaults straight to
// the A-Z browse list.
class GuidedSearchOptions extends ConsumerWidget {
  const GuidedSearchOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Row(
      children: [
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.child_care,
            label: 'Search by child',
            fill: AppColors.pastelFills[0],
            // Signed-out users have no children on their profile to search
            // by, so this needs a real account rather than falling through
            // to the sheet's own "no children yet" empty state.
            onTap: () => user == null ? context.push('/login') : showSearchByChildSheet(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.checklist_rtl,
            label: 'Guided search',
            fill: AppColors.pastelFills[1],
            onTap: () => context.push('/guided-search'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GuidedOptionCard(
            icon: Icons.sort_by_alpha,
            label: 'Browse A-Z',
            fill: AppColors.pastelFills[2],
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
  final Color fill;
  final VoidCallback onTap;

  const _GuidedOptionCard({required this.icon, required this.label, required this.fill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Neutral dark icon rather than a fixed brand hue, so it
              // reads cleanly against whichever pastel fill this card
              // gets — same convention as StatPill.
              Icon(icon, color: AppColors.onBackground),
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
