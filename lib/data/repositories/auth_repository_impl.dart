import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;
import 'package:uuid/uuid.dart';

import '../../core/errors/app_error.dart';
import '../../core/utils/result.dart';
import '../../domain/models/child.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../graphql/queries.dart';
import 'recipe_repository_impl.dart';

class AuthRepositoryImpl implements AuthRepository {
  final RecipeRepository _recipeRepository;
  AuthRepositoryImpl({RecipeRepository? recipeRepository})
      : _recipeRepository = recipeRepository ?? RecipeRepositoryImpl();

  @override
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String displayName,
    required String firstName,
    required String lastName,
    required DateTime birthdate,
    bool marketingOptIn = false,
  }) async {
    try {
      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: {
          CognitoUserAttributeKey.email: email,
          CognitoUserAttributeKey.name: displayName,
          CognitoUserAttributeKey.givenName: firstName,
          CognitoUserAttributeKey.familyName: lastName,
          // Cognito's birthdate attribute is a plain date string (no time
          // component), same YYYY-MM-DD convention already used for
          // Child.birthdate elsewhere in this app.
          CognitoUserAttributeKey.birthdate:
              '${birthdate.year.toString().padLeft(4, '0')}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}',
          // Read by WelcomeEmailLambda's Post Confirmation trigger to
          // decide whether to add this user to the SES marketing contact
          // list — Cognito custom attributes are always strings on the
          // wire, hence 'true'/'false' rather than a real bool.
          CognitoUserAttributeKey.custom('marketingOptIn'): marketingOptIn.toString(),
        }),
      );

      // Both complete and needs-confirmation are success — UI navigates to confirm screen
      return Success(_mockProfile(email, displayName));
    } on UsernameExistsException {
      // Account exists — try to resend confirmation code (only works for unconfirmed accounts)
      try {
        await Amplify.Auth.resendSignUpCode(username: email);
        // Unconfirmed account: let the user confirm
        return Success(_mockProfile(email, displayName));
      } catch (_) {
        // resendSignUpCode failed — account is already confirmed
        return const Failure(AlreadyRegisteredError());
      }
    } on InvalidPasswordException catch (e) {
      return Failure(AuthError(e.message));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(username: email, password: password);
      if (result.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        final name = await _fetchDisplayName() ?? user.username;
        return Success(await _ensureUserProfile(id: user.userId, email: email, displayName: name));
      }
      return const Failure(AuthError('Sign-in failed. Please try again.'));
    } on UserNotFoundException {
      return const Failure(AuthError('No account found with this email.'));
    } on AuthNotAuthorizedException {
      return const Failure(AuthError('Incorrect password. Please try again.'));
    } on UserNotConfirmedException {
      try { await Amplify.Auth.resendSignUpCode(username: email); } catch (_) {}
      return Failure(NotConfirmedError(email));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await Amplify.Auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> confirmSignUp({
    required String email,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: confirmationCode,
      );
      return const Success(null);
    } on CodeMismatchException {
      return const Failure(AuthError('Invalid confirmation code. Please try again.'));
    } on ExpiredCodeException {
      return const Failure(AuthError('Confirmation code expired. Please request a new one.'));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> resendConfirmationCode(String email) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> forgotPassword(String email) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
      return const Success(null);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> confirmForgotPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return const Success(null);
    } on CodeMismatchException {
      return const Failure(AuthError('Invalid code. Please try again.'));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  // Null (not empty string) when the attribute isn't set — pre-existing
  // Cognito users signed up before given_name/family_name/birthdate were
  // collected won't have them.
  String? _attrValue(List<AuthUserAttribute> attrs, CognitoUserAttributeKey key) {
    final match = attrs.where((a) => a.userAttributeKey == key);
    if (match.isEmpty) return null;
    final value = match.first.value;
    return value.isEmpty ? null : value;
  }

  @override
  Future<Result<UserProfile?>> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser()
          .timeout(const Duration(seconds: 6));
      final attrs = await Amplify.Auth.fetchUserAttributes()
          .timeout(const Duration(seconds: 6));
      final email = attrs.firstWhere(
        (a) => a.userAttributeKey == CognitoUserAttributeKey.email,
        orElse: () => const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.email, value: ''),
      ).value;
      final name = attrs.firstWhere(
        (a) => a.userAttributeKey == CognitoUserAttributeKey.name,
        orElse: () => const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.name, value: 'User'),
      ).value;
      return Success(await _ensureUserProfile(
        id: user.userId,
        email: email,
        displayName: name,
        firstName: _attrValue(attrs, CognitoUserAttributeKey.givenName),
        lastName: _attrValue(attrs, CognitoUserAttributeKey.familyName),
        birthdate: _attrValue(attrs, CognitoUserAttributeKey.birthdate),
      ));
    } on SignedOutException {
      return const Success(null);
    } catch (_) {
      return const Success(null);
    }
  }

  @override
  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.name,
        value: profile.displayName,
      );
      // This used to stop here and just echo the input back — bio/avatarUrl/
      // country/region/culturalBackground/cookingStyle/children never
      // actually persisted to AppSync. Cognito only owns displayName; the
      // rest of the profile has to go through updateUserProfile.
      final request = GraphQLRequest<String>(
        document: RecipeMutations.updateUserProfile,
        variables: {
          'input': {
            'id': profile.id,
            'displayName': profile.displayName,
            'bio': profile.bio,
            'avatarUrl': profile.avatarUrl,
            'country': profile.country,
            'region': profile.region,
            'culturalBackground': profile.culturalBackground,
            'cookingStyle': profile.cookingStyle,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
            'children': profile.children.map((c) => c.toJson()).toList(),
          },
        },
      );
      final response = await Amplify.API.mutate(request: request).response;
      if (response.errors.isNotEmpty) return Failure(ServerError(response.errors.first.message));
      final data = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
      return Success(UserProfile.fromJson(data['updateUserProfile'] as Map<String, dynamic>));
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<UserProfile>> addChild(String name, DateTime birthdate) async {
    final currentResult = await getCurrentUser();
    return currentResult.when(
      success: (profile) async {
        if (profile == null) return const Failure(AuthError('Not signed in.'));
        final child = Child(id: const Uuid().v4(), name: name, birthdate: birthdate, createdAt: DateTime.now().toUtc());
        return updateProfile(profile.copyWith(children: [...profile.children, child]));
      },
      failure: (e) async => Failure(e),
    );
  }

  @override
  Future<Result<UserProfile>> updateChild(Child updated) async {
    final currentResult = await getCurrentUser();
    return currentResult.when(
      success: (profile) async {
        if (profile == null) return const Failure(AuthError('Not signed in.'));
        final children = profile.children.map((c) => c.id == updated.id ? updated : c).toList();
        return updateProfile(profile.copyWith(children: children));
      },
      failure: (e) async => Failure(e),
    );
  }

  @override
  Future<Result<UserProfile>> removeChild(String childId) async {
    final currentResult = await getCurrentUser();
    return currentResult.when(
      success: (profile) async {
        if (profile == null) return const Failure(AuthError('Not signed in.'));
        // Delete the child's folder entries first so removing them from the
        // profile never leaves orphaned rows in ChildFoldersTable.
        final foldersResult = await _recipeRepository.getChildFolderEntries(childId);
        await foldersResult.when(
          success: (entries) async {
            for (final entry in entries) {
              await _recipeRepository.removeFromChildFolder(childId, entry.folder, entry.recipeId);
            }
          },
          failure: (_) async {},
        );
        final children = profile.children.where((c) => c.id != childId).toList();
        return updateProfile(profile.copyWith(children: children));
      },
      failure: (e) async => Failure(e),
    );
  }

  @override
  // Auth state changes are handled via getCurrentUser() polling in providers.
  // Replace with Amplify Hub subscription when needed.
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  bool get isSignedIn {
    // Synchronous check — use getCurrentUser() for accurate async state
    try {
      Amplify.Auth.getCurrentUser();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _fetchDisplayName() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();
      final name = attrs.firstWhere(
        (a) => a.userAttributeKey == CognitoUserAttributeKey.name,
        orElse: () => const AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.name, value: ''),
      ).value;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Reads the backend UserProfile record for [id], creating it on the
  /// first sign-in if it doesn't exist yet. Falls back to a local-only
  /// profile if the backend call fails, so auth still works offline or if
  /// AppSync is unreachable — the record just won't be persisted that time.
  Future<UserProfile> _ensureUserProfile({
    required String id,
    required String email,
    required String displayName,
    String? firstName,
    String? lastName,
    String? birthdate,
  }) async {
    try {
      final getRequest = GraphQLRequest<String>(
        document: RecipeQueries.getUserProfile,
        variables: {'id': id},
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;
      if (getResponse.errors.isEmpty) {
        final data = jsonDecode(getResponse.data ?? '{}') as Map<String, dynamic>;
        final existing = data['getUserProfile'] as Map<String, dynamic>?;
        if (existing != null) return UserProfile.fromJson(existing);
      }

      final createRequest = GraphQLRequest<String>(
        document: RecipeMutations.createUserProfile,
        variables: {
          'input': {
            'id': id,
            'displayName': displayName,
            'email': email,
            if (firstName != null) 'firstName': firstName,
            if (lastName != null) 'lastName': lastName,
            if (birthdate != null) 'birthdate': birthdate,
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          },
        },
      );
      final createResponse = await Amplify.API.mutate(request: createRequest).response;
      if (createResponse.errors.isEmpty) {
        final data = jsonDecode(createResponse.data ?? '{}') as Map<String, dynamic>;
        final created = data['createUserProfile'] as Map<String, dynamic>?;
        if (created != null) return UserProfile.fromJson(created);
      }
    } catch (_) {
      // Fall through to the local fallback below.
    }
    return _mockProfile(email, displayName, id: id);
  }

  UserProfile _mockProfile(String email, String name, {String? id}) => UserProfile(
        id: id ?? email,
        displayName: name,
        email: email,
        createdAt: DateTime.now(),
      );
}
