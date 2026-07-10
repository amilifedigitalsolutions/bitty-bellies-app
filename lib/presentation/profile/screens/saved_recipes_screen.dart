import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../home/providers/recipe_provider.dart';
import '../../recipe/widgets/recipe_card.dart';

class SavedRecipesScreen extends ConsumerWidget {
  final bool embedded;
  const SavedRecipesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedRecipesProvider);
    final body = savedAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return const EmptyView(
            message: 'No saved recipes yet',
            subMessage: 'Tap the bookmark icon on any recipe to save it here.',
            icon: Icons.bookmark_outline,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RecipeCard(
              recipe: recipes[i],
              onTap: () => context.push('/recipe/${recipes[i].id}'),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(savedRecipesProvider)),
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved recipes')),
      body: body,
    );
  }
}
