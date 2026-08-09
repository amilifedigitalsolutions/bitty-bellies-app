import '../models/child_folder_entry.dart';
import '../models/recipe.dart';
import '../models/recipe_comment.dart';
import '../models/recipe_filter.dart';
import '../models/saved_recipe.dart';
import '../../core/utils/result.dart';

abstract class RecipeRepository {
  // Browsing — no auth required
  Future<Result<RecipePage>> getRecipes({RecipeFilter filter = RecipeFilter.empty, String? nextToken, int limit = 20});
  Future<Result<Recipe>> getRecipeById(String id);
  Future<Result<List<Recipe>>> getRecipesByCreator(String creatorId, {String? nextToken});
  Future<Result<List<String>>> getAvailableCuisines();

  // Auth-required
  Future<Result<Recipe>> createRecipe(Recipe recipe);
  Future<Result<Recipe>> updateRecipe(Recipe recipe);
  Future<Result<void>> deleteRecipe(String id);

  // Save / unsave
  Future<Result<SavedRecipe>> saveRecipe(String recipeId);
  Future<Result<void>> unsaveRecipe(String recipeId);
  Future<Result<List<SavedRecipe>>> getSavedRecipes({String? nextToken});
  Future<Result<bool>> isRecipeSaved(String recipeId);

  // Comments
  Future<Result<List<RecipeComment>>> getComments(String recipeId, {String? nextToken});
  Future<Result<RecipeComment>> addComment(String recipeId, String body, {String? parentCommentId});
  Future<Result<RecipeComment>> updateComment(String commentId, String body);
  Future<Result<void>> deleteComment(String commentId, String recipeId);

  // Feedback
  Future<Result<List<RecipeFeedback>>> getFeedback(String recipeId, {String? nextToken});
  Future<Result<RecipeFeedback>> addFeedback(String recipeId, RecipeFeedback feedback);

  // Reports
  Future<Result<void>> reportRecipe(String recipeId, String reason, {String? details});
  Future<Result<void>> reportComment(String commentId, String recipeId, String reason, {String? details});

  // Email share
  Future<Result<void>> emailRecipe(String recipeId, String toEmail);

  // Child recipe folders (4.4)
  Future<Result<ChildRecipeFolderEntry>> saveToChildFolder(String childId, String folder, String recipeId);
  Future<Result<void>> removeFromChildFolder(String childId, String folder, String recipeId);
  Future<Result<List<ChildRecipeFolderEntry>>> getChildFolderEntries(String childId);
}
