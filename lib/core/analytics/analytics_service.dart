import 'package:logging/logging.dart';

// Analytics abstraction layer — swap the provider without changing callers.
// Currently logs to console. Wire up Pinpoint, PostHog, Amplitude, or
// Mixpanel by replacing the body of _dispatch().
abstract class AnalyticsEvent {
  String get name;
  Map<String, Object?> get properties;
}

class RecipeViewedEvent implements AnalyticsEvent {
  final String recipeId;
  final String? cuisine;
  const RecipeViewedEvent({required this.recipeId, this.cuisine});

  @override
  String get name => 'recipe_viewed';
  @override
  Map<String, Object?> get properties => {'recipe_id': recipeId, 'cuisine': cuisine};
}

class RecipeSavedEvent implements AnalyticsEvent {
  final String recipeId;
  const RecipeSavedEvent({required this.recipeId});

  @override
  String get name => 'recipe_saved';
  @override
  Map<String, Object?> get properties => {'recipe_id': recipeId};
}

class RecipeSharedEvent implements AnalyticsEvent {
  final String recipeId;
  final String method; // 'share_sheet' | 'email' | 'copy_link'
  const RecipeSharedEvent({required this.recipeId, required this.method});

  @override
  String get name => 'recipe_shared';
  @override
  Map<String, Object?> get properties => {'recipe_id': recipeId, 'method': method};
}

class RecipeUploadedEvent implements AnalyticsEvent {
  final String recipeId;
  const RecipeUploadedEvent({required this.recipeId});

  @override
  String get name => 'recipe_uploaded';
  @override
  Map<String, Object?> get properties => {'recipe_id': recipeId};
}

class SearchPerformedEvent implements AnalyticsEvent {
  final String query;
  final Map<String, dynamic> filters;
  const SearchPerformedEvent({required this.query, required this.filters});

  @override
  String get name => 'search_performed';
  @override
  Map<String, Object?> get properties => {'query': query, ...filters};
}

class UserRegisteredEvent implements AnalyticsEvent {
  @override
  String get name => 'user_registered';
  @override
  Map<String, Object?> get properties => {};
}

class UserSignedInEvent implements AnalyticsEvent {
  final String method; // 'email' | 'google' | 'apple'
  const UserSignedInEvent({required this.method});

  @override
  String get name => 'user_signed_in';
  @override
  Map<String, Object?> get properties => {'method': method};
}

class FeatureFlagViewedEvent implements AnalyticsEvent {
  final String flagName;
  final bool value;
  const FeatureFlagViewedEvent({required this.flagName, required this.value});

  @override
  String get name => 'feature_flag_viewed';
  @override
  Map<String, Object?> get properties => {'flag': flagName, 'enabled': value};
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  final _log = Logger('Analytics');

  // TODO: inject real provider (Pinpoint, PostHog, Amplitude) here
  Future<void> track(AnalyticsEvent event) async {
    _dispatch(event.name, event.properties);
  }

  void _dispatch(String name, Map<String, Object?> properties) {
    _log.info('[Analytics] $name $properties');
    // Example provider hooks (uncomment when wiring):
    // await Amplify.Analytics.recordEvent(event: AnalyticsEvent(name: name, properties: properties));
    // await PostHogFlutter.instance.capture(eventName: name, properties: properties);
  }

  void identifyUser(String userId, {Map<String, Object?>? traits}) {
    _log.info('[Analytics] identify user=$userId traits=$traits');
    // Provider-specific identity call goes here
  }

  void reset() {
    _log.info('[Analytics] reset (user signed out)');
  }
}
