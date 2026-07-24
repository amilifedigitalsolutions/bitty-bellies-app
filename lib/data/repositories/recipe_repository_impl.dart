import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_error.dart';
import '../../core/utils/result.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/recipe_comment.dart';
import '../../domain/models/recipe_filter.dart';
import '../../domain/models/saved_recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../graphql/queries.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  final _uuid = const Uuid();

  // ──────────────────────────────────────────────────────────────────────────
  // Browsing
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Recipe>>> getRecipes({
    RecipeFilter filter = RecipeFilter.empty,
    String? nextToken,
  }) async {
    try {
      final variables = <String, dynamic>{
        'limit': 20,
        if (nextToken != null) 'nextToken': nextToken,
        'filter': _buildFilter(filter),
      };

      final request = GraphQLRequest<String>(
        document: RecipeQueries.listRecipes,
        variables: variables,
        authorizationMode: APIAuthorizationType.iam,
      );

      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) {
        return Failure(ServerError(response.errors.first.message));
      }

      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['listRecipes']?['items'] as List? ?? [])
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();

      return Success(items);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<Recipe>> getRecipeById(String id) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeQueries.getRecipe,
        variables: {'id': id},
        authorizationMode: APIAuthorizationType.iam,
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) {
        return Failure(ServerError(response.errors.first.message));
      }
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final recipeJson = data['getRecipe'] as Map<String, dynamic>?;
      if (recipeJson == null) return const Failure(NotFoundError('Recipe not found.'));
      return Success(Recipe.fromJson(recipeJson));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<Recipe>>> getRecipesByCreator(String creatorId, {String? nextToken}) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeQueries.recipesByCreator,
        variables: {'creatorId': creatorId, 'limit': 20, if (nextToken != null) 'nextToken': nextToken},
        authorizationMode: APIAuthorizationType.iam,
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['recipesByCreatorId']?['items'] as List? ?? [])
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Create / update / delete
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<Recipe>> createRecipe(Recipe recipe) async {
    try {
      final input = _recipeToInput(recipe.copyWith(id: _uuid.v4()));
      final request = GraphQLRequest<String>(
        document: RecipeMutations.createRecipe,
        variables: {'input': input},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return Success(Recipe.fromJson(data['createRecipe'] as Map<String, dynamic>));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<Recipe>> updateRecipe(Recipe recipe) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeMutations.updateRecipe,
        variables: {'input': _recipeToInput(recipe)},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return Success(recipe);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteRecipe(String id) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeMutations.deleteRecipe,
        variables: {'input': {'id': id}},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Save / unsave
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<SavedRecipe>> saveRecipe(String recipeId) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final id = _uuid.v4();
      final request = GraphQLRequest<String>(
        document: RecipeMutations.saveRecipe,
        variables: {
          'input': {
            'id': id,
            'userId': user.userId,
            'recipeId': recipeId,
            'savedAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return Success(SavedRecipe(id: id, userId: user.userId, recipeId: recipeId, savedAt: DateTime.now()));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> unsaveRecipe(String recipeId) async {
    try {
      // The saved-recipe record's own id (not the recipe's id) is the
      // DynamoDB partition key, so it must be looked up before deleting.
      final savedResult = await getSavedRecipes();
      final savedId = savedResult.when(
        success: (saved) {
          for (final s in saved) {
            if (s.recipeId == recipeId) return s.id;
          }
          return null;
        },
        failure: (_) => null,
      );
      if (savedId == null) return const Success(null); // already not saved

      final request = GraphQLRequest<String>(
        document: RecipeMutations.unsaveRecipe,
        variables: {'input': {'id': savedId}},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<List<SavedRecipe>>> getSavedRecipes({String? nextToken}) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final request = GraphQLRequest<String>(
        document: RecipeQueries.getSavedRecipes,
        variables: {'userId': user.userId, 'limit': 20, if (nextToken != null) 'nextToken': nextToken},
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['savedRecipesByUserId']?['items'] as List? ?? [])
          .map((e) => SavedRecipe.fromJson(e as Map<String, dynamic>))
          .toList();

      // The GraphQL schema has no SavedRecipe.recipe field/resolver, so
      // savedRecipesByUserId only ever returns the bare join record. Hydrate
      // each one with its actual Recipe so callers (e.g. the Saved Recipes
      // screen) have something to render. A saved recipe that's since been
      // deleted just comes back with recipe: null and is filtered out by
      // callers, rather than failing the whole list.
      final hydrated = await Future.wait(items.map((s) async {
        final recipeResult = await getRecipeById(s.recipeId);
        return SavedRecipe(
          id: s.id,
          userId: s.userId,
          recipeId: s.recipeId,
          recipe: recipeResult.when(success: (r) => r, failure: (_) => null),
          savedAt: s.savedAt,
        );
      }));
      return Success(hydrated);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<bool>> isRecipeSaved(String recipeId) async {
    // For MVP, check via list; optimize later with a direct DynamoDB lookup
    final result = await getSavedRecipes();
    return result.when(
      success: (saved) => Success(saved.any((s) => s.recipeId == recipeId)),
      failure: (_) => const Success(false),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Comments
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<RecipeComment>>> getComments(String recipeId, {String? nextToken}) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeQueries.getComments,
        variables: {'recipeId': recipeId, 'limit': 50, if (nextToken != null) 'nextToken': nextToken},
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['commentsByRecipeId']?['items'] as List? ?? [])
          .map((e) => RecipeComment.fromJson(e as Map<String, dynamic>))
          .where((c) => !c.isDeleted && !c.isHidden)
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<RecipeComment>> addComment(String recipeId, String body, {String? parentCommentId}) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final id = _uuid.v4();
      final request = GraphQLRequest<String>(
        document: RecipeMutations.createComment,
        variables: {
          'input': {
            'id': id,
            'recipeId': recipeId,
            'authorId': user.userId,
            'authorName': user.username,
            'body': body,
            if (parentCommentId != null) 'parentCommentId': parentCommentId,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return Success(RecipeComment.fromJson(data['createRecipeComment'] as Map<String, dynamic>));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteComment(String commentId) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeMutations.deleteComment,
        variables: {'input': {'id': commentId}},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Feedback
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<RecipeFeedback>>> getFeedback(String recipeId, {String? nextToken}) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeQueries.getFeedback,
        variables: {'recipeId': recipeId, 'limit': 50},
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['feedbackByRecipeId']?['items'] as List? ?? [])
          .map((e) => RecipeFeedback.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<RecipeFeedback>> addFeedback(String recipeId, RecipeFeedback feedback) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeMutations.createFeedback,
        variables: {'input': feedback.toJson()},
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return Success(feedback);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Questions
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<RecipeQuestion>>> getQuestions(String recipeId, {String? nextToken}) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeQueries.getQuestions,
        variables: {'recipeId': recipeId, 'limit': 50},
      );
      final response = await Amplify.API.query(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      final items = (data['questionsByRecipeId']?['items'] as List? ?? [])
          .map((e) => RecipeQuestion.fromJson(e as Map<String, dynamic>))
          .where((q) => !q.isHidden)
          .toList();
      return Success(items);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<RecipeQuestion>> addQuestion(String recipeId, String question) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final id = _uuid.v4();
      final request = GraphQLRequest<String>(
        document: RecipeMutations.createQuestion,
        variables: {
          'input': {
            'id': id,
            'recipeId': recipeId,
            'authorId': user.userId,
            'authorName': user.username,
            'question': question,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return Success(RecipeQuestion.fromJson(data['createRecipeQuestion'] as Map<String, dynamic>));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<RecipeQuestion>> answerQuestion(String questionId, String answer) async {
    try {
      final request = GraphQLRequest<String>(
        document: RecipeMutations.answerQuestion,
        variables: {
          'input': {
            'id': questionId,
            'isAnsweredByCreator': true,
            'creatorAnswer': answer,
            'answeredAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return Success(RecipeQuestion.fromJson(data['updateRecipeQuestion'] as Map<String, dynamic>));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Reports
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> reportRecipe(String recipeId, String reason, {String? details}) async {
    return _createReport(recipeId: recipeId, reason: reason, details: details);
  }

  @override
  Future<Result<void>> reportComment(String commentId, String recipeId, String reason, {String? details}) async {
    return _createReport(recipeId: recipeId, commentId: commentId, reason: reason, details: details);
  }

  @override
  Future<Result<void>> reportQuestion(String questionId, String recipeId, String reason, {String? details}) async {
    return _createReport(recipeId: recipeId, questionId: questionId, reason: reason, details: details);
  }

  Future<Result<void>> _createReport({
    required String recipeId,
    String? commentId,
    String? questionId,
    required String reason,
    String? details,
  }) async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final request = GraphQLRequest<String>(
        document: RecipeMutations.createReport,
        variables: {
          'input': {
            'id': _uuid.v4(),
            'recipeId': recipeId,
            if (commentId != null) 'commentId': commentId,
            if (questionId != null) 'questionId': questionId,
            'reporterId': user.userId,
            'reason': reason,
            if (details != null) 'details': details,
            'status': 'PENDING',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          }
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Email share (via Lambda + SES — stub for MVP)
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> emailRecipe(String recipeId, String toEmail) async {
    // MVP: call a REST API endpoint backed by Lambda + SES
    // TODO: replace with real API Gateway call once Lambda is deployed
    await Future.delayed(const Duration(seconds: 1));
    return const Success(null);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildFilter(RecipeFilter filter) {
    final conditions = <Map<String, dynamic>>[
      {'status': {'eq': 'PUBLISHED'}},
    ];

    if (filter.query != null && filter.query!.isNotEmpty) {
      conditions.add({
        'or': [
          {'title': {'contains': filter.query}},
          {'description': {'contains': filter.query}},
        ]
      });
    }
    if (filter.cuisines.isNotEmpty) {
      conditions.add({'or': filter.cuisines.map((c) => {'cuisine': {'eq': c}}).toList()});
    }
    if (filter.ageStages.isNotEmpty) {
      conditions.add({'or': filter.ageStages.map((a) => {'ageStage': {'eq': a}}).toList()});
    }
    if (filter.textures.isNotEmpty) {
      conditions.add({'or': filter.textures.map((t) => {'texture': {'eq': t}}).toList()});
    }
    if (filter.maxPrepTimeMinutes != null) {
      conditions.add({'prepTimeMinutes': {'le': filter.maxPrepTimeMinutes}});
    }

    return conditions.length == 1 ? conditions.first : {'and': conditions};
  }

  Map<String, dynamic> _recipeToInput(Recipe recipe) => {
        'id': recipe.id,
        'title': recipe.title,
        'description': recipe.description,
        'creatorId': recipe.creatorId,
        'creatorName': recipe.creatorName,
        'ingredients': jsonEncode(recipe.ingredients.map((i) => i.toJson()).toList()),
        'steps': jsonEncode(recipe.steps.map((s) => s.toJson()).toList()),
        'prepTimeMinutes': recipe.prepTimeMinutes,
        'cookTimeMinutes': recipe.cookTimeMinutes,
        'servings': recipe.servings,
        'ageStage': recipe.ageStage,
        'texture': recipe.texture,
        'cuisine': recipe.cuisine,
        'cultureRegion': recipe.cultureRegion,
        'mealCategories': recipe.mealCategories,
        'dietTypes': recipe.dietTypes,
        'allergens': recipe.allergens,
        'chokingHazardNotes': recipe.chokingHazardNotes,
        'safetyNotes': recipe.safetyNotes,
        'storageReheatingNotes': recipe.storageReheatingNotes,
        'creatorNotes': recipe.creatorNotes,
        'status': recipe.status,
        'tags': recipe.tags,
        'isSponsored': recipe.isSponsored,
        'isPremium': recipe.isPremium,
        'createdAt': recipe.createdAt.toUtc().toIso8601String(),
      };
}

extension _RecipeCopyWith on Recipe {
  Recipe copyWith({String? id}) => Recipe(
        id: id ?? this.id,
        title: title,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorAvatarUrl: creatorAvatarUrl,
        ingredients: ingredients,
        steps: steps,
        media: media,
        prepTimeMinutes: prepTimeMinutes,
        cookTimeMinutes: cookTimeMinutes,
        servings: servings,
        ageStage: ageStage,
        texture: texture,
        cuisine: cuisine,
        cultureRegion: cultureRegion,
        mealCategories: mealCategories,
        dietTypes: dietTypes,
        allergens: allergens,
        chokingHazardNotes: chokingHazardNotes,
        safetyNotes: safetyNotes,
        storageReheatingNotes: storageReheatingNotes,
        creatorNotes: creatorNotes,
        status: status,
        tags: tags,
        isSponsored: isSponsored,
        isPremium: isPremium,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
