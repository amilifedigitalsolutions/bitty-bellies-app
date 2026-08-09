import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../data/repositories/recipe_repository_impl.dart';
import '../../../domain/models/meal_window.dart';
import '../../../domain/models/recipe.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../../domain/repositories/recipe_repository.dart';
import '../../auth/providers/auth_provider.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) => RecipeRepositoryImpl());

// Active filter state
final recipeFilterProvider = StateProvider<RecipeFilter>((ref) => RecipeFilter.empty);

// Paginated recipe list state, shared by search results and the A-Z browse.
// nextToken == null means there are no more pages left to fetch.
class RecipeListState {
  final List<Recipe> items;
  final String? nextToken;
  final bool isLoading;
  final bool isLoadingMore;
  final AppError? error;

  const RecipeListState({
    this.items = const [],
    this.nextToken,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => nextToken != null;
}

// Recipe search results — reacts to filter changes, paginates via nextToken.
class RecipeSearchNotifier extends StateNotifier<RecipeListState> {
  RecipeSearchNotifier(this._ref) : super(const RecipeListState()) {
    _load();
    _ref.listen(recipeFilterProvider, (_, __) => _load());
  }

  final Ref _ref;

  Future<void> _load() async {
    state = const RecipeListState();
    final repo = _ref.read(recipeRepositoryProvider);
    final filter = _ref.read(recipeFilterProvider);
    final result = await repo.getRecipes(filter: filter);
    result.when(
      success: (page) => state = RecipeListState(items: page.items, nextToken: page.nextToken, isLoading: false),
      failure: (e) => state = RecipeListState(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = RecipeListState(items: state.items, nextToken: state.nextToken, isLoading: false, isLoadingMore: true);
    final repo = _ref.read(recipeRepositoryProvider);
    final filter = _ref.read(recipeFilterProvider);
    final result = await repo.getRecipes(filter: filter, nextToken: state.nextToken);
    result.when(
      success: (page) => state = RecipeListState(
        items: [...state.items, ...page.items],
        nextToken: page.nextToken,
        isLoading: false,
      ),
      failure: (_) => state = RecipeListState(items: state.items, nextToken: state.nextToken, isLoading: false),
    );
  }
}

final recipeSearchProvider = StateNotifierProvider.autoDispose<RecipeSearchNotifier, RecipeListState>(
  (ref) => RecipeSearchNotifier(ref),
);

// Which meal is "now", based on the device's local time — read once per
// provider container build rather than per rebuild, so it doesn't drift
// mid-session; a cold app relaunch is enough to pick up a new window.
final currentMealWindowProvider = Provider<MealWindow>((ref) => MealWindow.forTime(DateTime.now()));

// Home's "right now" recommendations — deliberately its own provider using
// a locally-built RecipeFilter, not recipeFilterProvider, so it can't be
// stomped by (or itself stomp) whatever filter state Search is holding;
// the two screens' recipe lists are independent. Not paginated — this is a
// bounded "right now" section, not a full browse.
final homeRecommendedRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final window = ref.watch(currentMealWindowProvider);
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getRecipes(filter: RecipeFilter(mealCategories: window.categories));
  return result.when(success: (page) => page.items, failure: (e) => throw e);
});

// Every recipe, sorted A-Z by title, for the Search screen's "Browse A-Z"
// index. Paginates via nextToken, re-sorting the accumulated list after
// each page — fine up to the low thousands of recipes; a genuinely huge
// catalog would want a maintained alphabetical index instead of client
// sort, same as availableCuisinesProvider's distinct-value caveat below.
class RecipeBrowseNotifier extends StateNotifier<RecipeListState> {
  RecipeBrowseNotifier(this._ref) : super(const RecipeListState()) {
    _load();
  }

  final Ref _ref;

  List<Recipe> _sorted(List<Recipe> list) =>
      List<Recipe>.from(list)..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  Future<void> _load() async {
    state = const RecipeListState();
    final repo = _ref.read(recipeRepositoryProvider);
    final result = await repo.getRecipes();
    result.when(
      success: (page) =>
          state = RecipeListState(items: _sorted(page.items), nextToken: page.nextToken, isLoading: false),
      failure: (e) => state = RecipeListState(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = RecipeListState(items: state.items, nextToken: state.nextToken, isLoading: false, isLoadingMore: true);
    final repo = _ref.read(recipeRepositoryProvider);
    final result = await repo.getRecipes(nextToken: state.nextToken);
    result.when(
      success: (page) => state = RecipeListState(
        items: _sorted([...state.items, ...page.items]),
        nextToken: page.nextToken,
        isLoading: false,
      ),
      failure: (_) => state = RecipeListState(items: state.items, nextToken: state.nextToken, isLoading: false),
    );
  }
}

final recipeBrowseProvider = StateNotifierProvider.autoDispose<RecipeBrowseNotifier, RecipeListState>(
  (ref) => RecipeBrowseNotifier(ref),
);

// Cuisines actually present in published recipes — drives the Home screen's
// filter pills so a pill is never shown with zero matching recipes.
final availableCuisinesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getAvailableCuisines();
  return result.when(success: (c) => c, failure: (_) => []);
});

// Single recipe detail
final recipeDetailProvider = FutureProvider.autoDispose.family<Recipe, String>((ref, id) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getRecipeById(id);
  return result.when(success: (r) => r, failure: (e) => throw e);
});

// The signed-in user's own recipes, across all statuses (including
// PENDING_REVIEW/DRAFT) — unlike recipeListProvider, which only shows
// PUBLISHED recipes to everyone. A recipe not yet approved should still
// be visible to its own creator under "My Recipes".
final myRecipesProvider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getRecipesByCreator(user.id);
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

// A child's saved-recipe folder entries — UI groups the flat list into the
// 4 fixed folders (AppConstants.recipeFolders) client-side.
final childFolderEntriesProvider = FutureProvider.autoDispose.family((ref, String childId) async {
  final repo = ref.read(recipeRepositoryProvider);
  final result = await repo.getChildFolderEntries(childId);
  return result.when(success: (e) => e, failure: (e) => throw e);
});
