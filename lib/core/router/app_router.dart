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
      // Shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
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
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/'),
    (icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search', path: '/search'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path) && (_tabs[i].path != '/' || location == '/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Shown in place instead of routing to a separate /splash page — a real
    // Navigator page transition here (splash page -> home page) was the
    // root cause of a recurring "duplicate page key" crash on cold start;
    // showing it as plain conditional content sidesteps that mechanism
    // entirely rather than trying to time around it.
    final authState = ref.watch(currentUserProvider);
    if (authState.isLoading) return const SplashScreen();

    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
