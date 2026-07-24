import '../models/recipe.dart';
import '../models/recipe_comment.dart';
import '../models/recipe_filter.dart';
import '../models/saved_recipe.dart';
import '../../core/utils/result.dart';

abstract class RecipeRepository {
  // Browsing — no auth required
  Future<Result<List<Recipe>>> getRecipes({RecipeFilter filter = RecipeFilter.empty, String? nextToken});
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
  Future<Result<void>> deleteComment(String commentId);

  // Feedback
  Future<Result<List<RecipeFeedback>>> getFeedback(String recipeId, {String? nextToken});
  Future<Result<RecipeFeedback>> addFeedback(String recipeId, RecipeFeedback feedback);

  // Questions
  Future<Result<List<RecipeQuestion>>> getQuestions(String recipeId, {String? nextToken});
  Future<Result<RecipeQuestion>> addQuestion(String recipeId, String question);
  Future<Result<RecipeQuestion>> answerQuestion(String questionId, String answer);

  // Reports
  Future<Result<void>> reportRecipe(String recipeId, String reason, {String? details});
  Future<Result<void>> reportComment(String commentId, String recipeId, String reason, {String? details});
  Future<Result<void>> reportQuestion(String questionId, String recipeId, String reason, {String? details});

  // Email share
  Future<Result<void>> emailRecipe(String recipeId, String toEmail);
}
