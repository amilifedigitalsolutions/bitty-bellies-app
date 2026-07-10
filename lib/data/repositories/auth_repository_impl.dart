import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart' hide UserProfile;

import '../../core/errors/app_error.dart';
import '../../core/utils/result.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: {
          CognitoUserAttributeKey.email: email,
          CognitoUserAttributeKey.name: displayName,
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
        return Success(_mockProfile(email, user.username));
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
      return Success(_mockProfile(email, name, id: user.userId));
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
      return Success(profile);
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
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

  UserProfile _mockProfile(String email, String name, {String? id}) => UserProfile(
        id: id ?? email,
        displayName: name,
        email: email,
        createdAt: DateTime.now(),
      );
}
