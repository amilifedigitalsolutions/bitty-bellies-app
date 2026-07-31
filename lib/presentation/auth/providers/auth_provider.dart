import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../home/providers/recipe_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(recipeRepository: ref.read(recipeRepositoryProvider)),
);

// Current signed-in user — null means guest
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserProfile?>>(
  (ref) => CurrentUserNotifier(ref.read(authRepositoryProvider)),
);

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repo;

  CurrentUserNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final result = await _repo.getCurrentUser();
    state = result.when(
      success: (user) => AsyncValue.data(user),
      failure: (_) => const AsyncValue.data(null),
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await _repo.signIn(email: email, password: password);
    state = result.when(
      success: (user) => AsyncValue.data(user),
      failure: (e) => AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<void> signUp({required String email, required String password, required String displayName}) async {
    state = const AsyncValue.loading();
    final result = await _repo.signUp(email: email, password: password, displayName: displayName);
    state = result.when(
      success: (user) => AsyncValue.data(null), // wait for confirm
      failure: (e) => AsyncValue.error(e, StackTrace.current),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() => _init();
}

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).whenOrNull(data: (u) => u != null) ?? false;
});
