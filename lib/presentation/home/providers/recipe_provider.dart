import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../../domain/repositories/recipe_repository.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) => RecipeRepositoryImpl());

// Active filter state
final recipeFilterProvider = StateProvider<RecipeFilter>((ref) => RecipeFilter.empty);

// Recipe list — reacts to filter changes
final recipeListProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  final filter = ref.watch(recipeFilterProvider);
  final result = await repo.getRecipes(filter: filter);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

// Single recipe detail
final recipeDetailProvider = FutureProvider.autoDispose.family<Recipe, String>((ref, id) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getRecipeById(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

// Saved recipes
final savedRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getSavedRecipes();
  return result.when(
    success: (saved) => saved.map((s) => s.recipe).whereType<Recipe>().toList(),
    failure: (e) => throw e,
  );
});

// Is a specific recipe saved?
final isRecipeSavedProvider = FutureProvider.autoDispose.family<bool, String>((ref, recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.isRecipeSaved(recipeId);
  return result.when(success: (v) => v, failure: (_) => false);
});

// Comments for a recipe
final recipeCommentsProvider = FutureProvider.autoDispose.family((ref, String recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getComments(recipeId);
  return result.when(success: (c) => c, failure: (e) => throw e);
});

// Feedback for a recipe
final recipeFeedbackProvider = FutureProvider.autoDispose.family((ref, String recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getFeedback(recipeId);
  return result.when(success: (f) => f, failure: (e) => throw e);
});

// Questions for a recipe
final recipeQuestionsProvider = FutureProvider.autoDispose.family((ref, String recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getQuestions(recipeId);
  return result.when(success: (q) => q, failure: (e) => throw e);
});
