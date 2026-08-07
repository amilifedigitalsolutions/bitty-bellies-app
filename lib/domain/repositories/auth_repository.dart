import '../models/child.dart';
import '../models/user_profile.dart';
import '../../core/utils/result.dart';

abstract class AuthRepository {
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String displayName,
    required String firstName,
    required String lastName,
    required DateTime birthdate,
    bool marketingOptIn = false,
  });

  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> confirmSignUp({
    required String email,
    required String confirmationCode,
  });

  Future<Result<void>> resendConfirmationCode(String email);

  Future<Result<void>> forgotPassword(String email);

  Future<Result<void>> confirmForgotPassword({
    required String email,
    required String newPassword,
    required String confirmationCode,
  });

  Future<Result<UserProfile?>> getCurrentUser();

  Future<Result<UserProfile>> updateProfile(UserProfile profile);

  // Children (4.3)
  Future<Result<UserProfile>> addChild(String name, DateTime birthdate);
  Future<Result<UserProfile>> updateChild(Child child);
  Future<Result<UserProfile>> removeChild(String childId);

  Stream<AuthState> get authStateChanges;

  bool get isSignedIn;
}

enum AuthState { signedIn, signedOut, loading }
