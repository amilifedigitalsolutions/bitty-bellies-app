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

    // Built as a Stack overlay rather than Scaffold.bottomNavigationBar —
    // that slot enforces its own bounds on the child in a way that was
    // silently discarding the custom curved clip (it rendered as a plain
    // flat edge no matter what). A Positioned PhysicalShape, the same
    // pattern already working for the header, renders the curve correctly.
    return Scaffold(
      body: Stack(
        children: [
          // Padding needs to clear not just the curved nav bar's own
          // height but its curve peak plus a screen's own FAB margin
          // above that peak (each screen's Scaffold, e.g. Home's "Share
          // recipe" FAB, floats relative to this padded area's bottom
          // edge, not the true screen edge).
          Padding(
            padding: const EdgeInsets.only(bottom: 140),
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PhysicalShape(
              clipper: const _CurvedBottomNavClipper(),
              color: Colors.white,
              elevation: 14,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              // NavigationBar is itself a Material with its own elevation —
              // nested inside another PhysicalShape, that second physical
              // layer was fighting the outer one and blanking out its clip
              // and shadow entirely. Flattening it (transparent + no
              // elevation) leaves the outer shape as the only surface.
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
          ),
        ],
      ),
    );
  }
}

// Mirror of Home's header curve, bulging upward in the center instead of
// down, for the bottom nav's top edge.
class _CurvedBottomNavClipper extends CustomClipper<Path> {
  const _CurvedBottomNavClipper();

  @override
  Path getClip(Size size) {
    // Stays within [0, size.height] the whole way — a path that dips into
    // negative y (above the widget's own box) gets silently clipped away
    // by Flutter's default paint bounds, which is why an earlier version
    // of this curve wasn't rendering at all.
    return Path()
      ..moveTo(0, 28)
      ..quadraticBezierTo(size.width / 2, 0, size.width, 28)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
