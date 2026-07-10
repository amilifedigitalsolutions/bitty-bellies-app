import 'package:equatable/equatable.dart';

class RecipeFilter extends Equatable {
  final String? query;
  final List<String> cuisines;
  final List<String> ageStages;
  final List<String> textures;
  final List<String> mealCategories;
  final List<String> dietTypes;
  final List<String> excludeAllergens;
  final int? maxPrepTimeMinutes;
  final String? sortBy; // 'newest' | 'popular' | 'rating'

  const RecipeFilter({
    this.query,
    this.cuisines = const [],
    this.ageStages = const [],
    this.textures = const [],
    this.mealCategories = const [],
    this.dietTypes = const [],
    this.excludeAllergens = const [],
    this.maxPrepTimeMinutes,
    this.sortBy = 'newest',
  });

  bool get hasActiveFilters =>
      query != null ||
      cuisines.isNotEmpty ||
      ageStages.isNotEmpty ||
      textures.isNotEmpty ||
      mealCategories.isNotEmpty ||
      dietTypes.isNotEmpty ||
      excludeAllergens.isNotEmpty ||
      maxPrepTimeMinutes != null;

  RecipeFilter copyWith({
    String? query,
    List<String>? cuisines,
    List<String>? ageStages,
    List<String>? textures,
    List<String>? mealCategories,
    List<String>? dietTypes,
    List<String>? excludeAllergens,
    int? maxPrepTimeMinutes,
    String? sortBy,
    bool clearQuery = false,
    bool clearMaxPrepTime = false,
  }) {
    return RecipeFilter(
      query: clearQuery ? null : (query ?? this.query),
      cuisines: cuisines ?? this.cuisines,
      ageStages: ageStages ?? this.ageStages,
      textures: textures ?? this.textures,
      mealCategories: mealCategories ?? this.mealCategories,
      dietTypes: dietTypes ?? this.dietTypes,
      excludeAllergens: excludeAllergens ?? this.excludeAllergens,
      maxPrepTimeMinutes: clearMaxPrepTime ? null : (maxPrepTimeMinutes ?? this.maxPrepTimeMinutes),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  static const RecipeFilter empty = RecipeFilter();

  @override
  List<Object?> get props => [
        query,
        cuisines,
        ageStages,
        textures,
        mealCategories,
        dietTypes,
        excludeAllergens,
        maxPrepTimeMinutes,
        sortBy,
      ];
}
