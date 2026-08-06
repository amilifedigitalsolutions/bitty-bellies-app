import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/recipe_provider.dart';
import '../../profile/screens/saved_recipes_screen.dart' show AddEditChildSheet;

void showSearchByChildSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _SearchByChildSheet(),
  );
}

class _SearchByChildSheet extends ConsumerWidget {
  const _SearchByChildSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: userAsync.when(
          data: (user) {
            final children = user?.children ?? const [];
            if (children.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No children yet', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    "Add a child and we'll match recipes to their age automatically.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => const AddEditChildSheet(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add child'),
                  ),
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search by child', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Shows recipes that are age-appropriate for the child you pick.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...children.map((c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.child_care)),
                      title: Text(c.name),
                      subtitle: Text(c.ageLabel),
                      onTap: () {
                        ref.read(recipeFilterProvider.notifier).update(
                              (_) => RecipeFilter(ageStages: c.matchingAgeStages(AppConstants.ageStages)),
                            );
                        Navigator.pop(context);
                        // This sheet is opened from Home now, so a plain
                        // pop would just close it there — go to Search to
                        // actually show the filtered results.
                        context.go('/search');
                      },
                    )),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
