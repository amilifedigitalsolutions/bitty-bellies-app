// Feature flag abstraction — all monetization & experimental gates live here.
// Toggle via remote config (AppSync, LaunchDarkly, AWS AppConfig) later.
class FeatureFlags {
  FeatureFlags._();

  // Monetization (all off for MVP)
  static const bool sponsoredRecipes = false;
  static const bool premiumCollections = false;
  static const bool subscriptionTier = false;
  static const bool affiliateLinks = false;
  static const bool ads = false;
  static const bool brandPartnerships = false;
  static const bool paidCreatorFeatures = false;
  static const bool mealPlanning = false;

  // Social / DMs (off for MVP — questions are public)
  static const bool privateMessaging = false;

  // Auth providers
  static const bool googleSignIn = false;
  static const bool appleSignIn = false;

  // Search
  static const bool openSearch = false; // DynamoDB filters only for MVP
}
