import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/recipe.dart';
import '../../home/providers/recipe_provider.dart';
import '../../recipe/widgets/recipe_row_card.dart';

// Plain alphabetically-grouped listing rather than a fast-scroll side index
// (like Contacts) — the recipe catalog is small enough at MVP volume that
// a sectioned scroll is enough; worth revisiting once it grows.
class BrowseAllScreen extends ConsumerWidget {
  const BrowseAllScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesAlphabeticalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse all recipes')),
      body: recipesAsync.when(
        data: (recipes) {
          if (recipes.isEmpty) {
            return const EmptyView(message: 'No recipes yet', subMessage: 'Check back soon.');
          }
          final groups = <String, List<Recipe>>{};
          for (final r in recipes) {
            final first = r.title.isNotEmpty ? r.title[0].toUpperCase() : '#';
            final letter = RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
            groups.putIfAbsent(letter, () => []).add(r);
          }
          final letters = groups.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: letters.length,
            itemBuilder: (context, i) {
              final letter = letters[i];
              final items = groups[letter]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      letter,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                  ...items.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RecipeRowCard(recipe: r, onTap: () => context.push('/recipe/${r.id}')),
                      )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: 'Could not load recipes. Check your connection.',
          onRetry: () => ref.invalidate(allRecipesAlphabeticalProvider),
        ),
      ),
    );
  }
}
