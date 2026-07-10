import 'package:equatable/equatable.dart';
import 'recipe.dart';

class SavedRecipe extends Equatable {
  final String id;
  final String userId;
  final String recipeId;
  final Recipe? recipe;
  final DateTime savedAt;

  const SavedRecipe({
    required this.id,
    required this.userId,
    required this.recipeId,
    this.recipe,
    required this.savedAt,
  });

  factory SavedRecipe.fromJson(Map<String, dynamic> json) => SavedRecipe(
        id: json['id'] as String,
        userId: json['userId'] as String,
        recipeId: json['recipeId'] as String,
        recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>) : null,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'recipeId': recipeId,
        'recipe': recipe?.toJson(),
        'savedAt': savedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, recipeId];
}
