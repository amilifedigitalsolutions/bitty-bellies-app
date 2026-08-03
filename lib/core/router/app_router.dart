import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/recipe.dart';
import '../../presentation/auth/providers/auth_provider.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/auth/screens/confirm_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/recipe/screens/recipe_detail_screen.dart';
import '../../presentation/search/screens/search_screen.dart';
import '../../presentation/upload/screens/upload_recipe_screen.dart';
import '../../presentation/profile/screens/profile_screen.dart';
import '../../presentation/profile/screens/saved_recipes_screen.dart';
import '../../presentation/settings/screens/settings_screen.dart';
import '../../presentation/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Shell with bottom nav. StatefulShellRoute.indexedStack keeps each
      // tab's own persistent Navigator alive in an IndexedStack instead of
      // page-transitioning between shell and non-shell routes — plain
      // ShellRoute hit a long-standing, still-open upstream go_router bug
      // (flutter/flutter #107010, #107045, #122507, #140586, #156585)
      // where navigating in and out of the shell could produce a Navigator
      // page with a duplicate key. The branch-based model here sidesteps
      // that mechanism entirely rather than working around its timing.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (_, __) => const SearchScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),

      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/confirm', builder: (_, state) => ConfirmScreen(email: state.uri.queryParameters['email'] ?? '')),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // Recipe
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) => RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),

      // Upload — auth guarded
      GoRoute(
        path: '/upload',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user == null) return '/login?redirect=/upload';
          return null;
        },
        builder: (_, state) => UploadRecipeScreen(existingRecipe: state.extra as Recipe?),
      ),

      // Saved recipes — auth guarded
      GoRoute(
        path: '/saved',
        redirect: (context, state) {
          final user = ref.read(currentUserProvider).valueOrNull;
          if (user == null) return '/login?redirect=/saved';
          return null;
        },
        builder: (_, __) => const SavedRecipesScreen(),
      ),

      // Settings
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AppShell({super.key, required this.navigationShell});

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shown in place instead of routing to a separate /splash page — a real
    // Navigator page transition here (splash page -> home page) was one of
    // several contributors to the duplicate-page-key crash; showing it as
    // plain conditional content sidesteps that mechanism entirely.
    final authState = ref.watch(currentUserProvider);
    if (authState.isLoading) return const SplashScreen();

    return Scaffold(
      body: navigationShell,
      // Curved top corners + a soft shadow, mirroring the curved gradient
      // header on Home — bookends the screen with matching rounded/lifted
      // shapes at the top and bottom instead of a flat-edged bar.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            destinations: _tabs
                .map((t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: t.label,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
