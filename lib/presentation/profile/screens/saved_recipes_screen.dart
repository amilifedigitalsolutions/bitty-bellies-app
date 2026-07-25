import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/recipe.dart';
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
            child: Stack(
              children: [
                RecipeCard(
                  recipe: recipes[i],
                  onTap: () => context.push('/recipe/${recipes[i].id}'),
                ),
                Positioned(top: 8, right: 8, child: _RemoveButton(recipe: recipes[i])),
              ],
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

// Lets a member unsave a recipe directly from the list, without having to
// open its detail page first.
class _RemoveButton extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _RemoveButton({required this.recipe});

  @override
  ConsumerState<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends ConsumerState<_RemoveButton> {
  bool _removing = false;

  Future<void> _remove() async {
    setState(() => _removing = true);
    final result = await ref.read(recipeRepositoryProvider).unsaveRecipe(widget.recipe.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(savedRecipesProvider);
        ref.invalidate(isRecipeSavedProvider(widget.recipe.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved recipes')),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: ${e.message}'), backgroundColor: AppColors.error),
        );
        setState(() => _removing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: _removing
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          : IconButton(
              icon: const Icon(Icons.bookmark_remove_outlined, color: Colors.white, size: 20),
              tooltip: 'Remove from saved',
              onPressed: _remove,
            ),
    );
  }
}
