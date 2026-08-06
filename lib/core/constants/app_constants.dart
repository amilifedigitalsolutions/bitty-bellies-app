class AppConstants {
  AppConstants._();

  static const String appName = 'Bitty Bellies';
  static const String appTagline = 'Real recipes from real parents, from around the world.';

  // Recipe media storage — matches the bucket/region configured in
  // amplify_config.dart's awsS3StoragePlugin.
  static const String s3MediaBucket = 'blw-recipes-media-324062893587-us-east-1';
  static const String s3MediaRegion = 'us-east-1';

  // Pagination
  static const int pageSize = 20;

  // Age stages
  static const List<String> ageStages = [
    '4 - 6 months',
    '6 - 12 months',
    '12+ months',
  ];

  // Texture/format
  static const List<String> textures = [
    'Puree',
    'Mashed',
    'Soft solids',
    'Finger food',
    'Family meal adaptation',
    'Mixed',
  ];

  // Ingredient measurement units
  static const List<String> units = [
    'tsp',
    'tbsp',
    'cup',
    'ml',
    'l',
    'g',
    'kg',
    'oz',
    'piece',
    'slice',
    'clove',
    'pinch',
    'to taste',
  ];

  // Meal categories
  // No "Any" catch-all: creators can already multi-select every category
  // that applies, and a recipe tagged only "Any" wouldn't actually surface
  // under a specific meal-type filter (e.g. "Breakfast") since the filter
  // matches exact tag values — so "Any" was both redundant and broken.
  static const List<String> mealCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Drink',
  ];

  // Fixed set of per-child recipe folders (4.4) — display labels; the API
  // stores these upper-cased to match the RecipeFolder GraphQL enum.
  static const List<String> recipeFolders = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  // Diet types
  static const List<String> dietTypes = [
    'Vegetarian',
    'Vegan',
    'Halal',
    'Kosher',
    'Dairy-free',
    'Egg-free',
    'Gluten-free',
    'Nut-free',
    'Soy-free',
    'Fish-free',
    'Shellfish-free',
    'Low-sugar',
    'No added salt',
  ];

  // Allergens (top 14 EU + common)
  static const List<String> allergens = [
    'Milk/Dairy',
    'Eggs',
    'Peanuts',
    'Tree Nuts',
    'Fish',
    'Shellfish',
    'Wheat/Gluten',
    'Soy',
    'Sesame',
    'Mustard',
    'Celery',
    'Lupin',
    'Molluscs',
    'Sulphites',
  ];

  // Cuisines
  static const List<String> cuisines = [
    'African',
    'American',
    'Asian',
    'British',
    'Caribbean',
    'Chinese',
    'Eastern European',
    'French',
    'Greek',
    'Indian',
    'Italian',
    'Japanese',
    'Korean',
    'Latin American',
    'Mediterranean',
    'Mexican',
    'Middle Eastern',
    'Moroccan',
    'Nordic',
    'Pakistani',
    'Persian',
    'South American',
    'Spanish',
    'Thai',
    'Turkish',
    'Vietnamese',
    'West African',
    'Other',
  ];

  // Safety disclaimer
  static const String safetyDisclaimer =
      'Always supervise your baby during meal times. '
      'Recipes on this app are shared by other parents and are not medical advice. '
      'Consult your pediatrician or health visitor before introducing new foods. '
      'Follow your local pediatric feeding guidance.';

  // Recipe visibility statuses
  static const String statusDraft = 'DRAFT';
  static const String statusPending = 'PENDING_REVIEW';
  static const String statusPublished = 'PUBLISHED';
  static const String statusRejected = 'REJECTED';
  static const String statusRemoved = 'REMOVED';

  // Report reasons
  static const List<String> reportReasons = [
    'Unsafe for babies',
    'Medical misinformation',
    'Inaccurate allergen information',
    'Inappropriate content',
    'Spam',
    'Copyright violation',
    'Other',
  ];
}
