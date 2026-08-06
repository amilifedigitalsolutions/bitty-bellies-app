import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../recipe/widgets/recipe_card.dart';
import '../providers/recipe_provider.dart';

// Flat, minimal top section instead of a decorative curved/gradient hero —
// both leading apps in this exact category (Solid Starts for BLW, Tasty for
// recipes) use an understated top bar and let search + content cards carry
// the screen, rather than a big colored header block. This also drops the
// PhysicalShape/clipper/GlobalKey-height-measurement machinery the curved
// version needed, which was the source of most of its bugs.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final recipesAsync = ref.watch(homeRecommendedRecipesProvider);
    final mealWindow = ref.watch(currentMealWindowProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // White backdrop chip behind the wordmark — the
                        // logo's baby illustration is skin/cream toned and
                        // reads better with something behind it than
                        // sitting directly on the page background.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Image.asset('assets/logos/logo-long.png', height: 24, fit: BoxFit.contain),
                        ),
                        const Spacer(),
                        if (user == null)
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: const Text('Sign in'),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.bookmark_outline),
                            onPressed: () => context.push('/saved'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${mealWindow.label} on your mind?',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // Tap-through search bar — routes to the Search screen,
                    // which owns all actual browsing/filtering.
                    Material(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.go('/search'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Search recipes, ingredients, cultures...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Safety disclaimer banner — flat pastel block, no
                    // border, matching the app-wide Wonder-Weeks-style
                    // color-blocking rather than a bordered "alert" look.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.child_care, color: AppColors.primaryDark, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Always supervise feeding. These recipes come from parents like you — not medical advice.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      '${mealWindow.label} recipes other parents are loving',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return SliverFillRemaining(
                  child: EmptyView(
                    message: 'No ${mealWindow.label.toLowerCase()} recipes yet',
                    subMessage: 'Try Search to browse everything.',
                    icon: Icons.no_food,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: RecipeCard(
                        recipe: recipes[i],
                        onTap: () => context.push('/recipe/${recipes[i].id}'),
                      ),
                    ),
                    childCount: recipes.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: RecipeCardSkeleton(),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: 'Could not load recipes. Check your connection.',
                onRetry: () => ref.invalidate(homeRecommendedRecipesProvider),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),

      // Upload FAB — auth-aware
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final u = ref.read(currentUserProvider).valueOrNull;
          if (u == null) {
            context.push('/login?redirect=/upload');
          } else {
            context.push('/upload');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Share recipe'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
