import 'package:equatable/equatable.dart';
import 'recipe.dart';

class ChildRecipeFolderEntry extends Equatable {
  final String childId;
  final String folder; // one of AppConstants.recipeFolders, upper-cased for the API
  final String recipeId;
  final Recipe? recipe;
  final DateTime createdAt;

  const ChildRecipeFolderEntry({
    required this.childId,
    required this.folder,
    required this.recipeId,
    this.recipe,
    required this.createdAt,
  });

  factory ChildRecipeFolderEntry.fromJson(Map<String, dynamic> json) => ChildRecipeFolderEntry(
        childId: json['childId'] as String,
        folder: json['folder'] as String,
        recipeId: json['recipeId'] as String,
        recipe: json['recipe'] != null ? Recipe.fromJson(json['recipe'] as Map<String, dynamic>) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  List<Object?> get props => [childId, folder, recipeId];
}
