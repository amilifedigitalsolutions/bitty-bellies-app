import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../recipe/widgets/recipe_card.dart';
import '../providers/recipe_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final recipesAsync = ref.watch(recipeListProvider);
    final filter = ref.watch(recipeFilterProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Curved gradient header — spans from the very top of the screen
          // down through the logo, meal-type chips, and safety banner,
          // ending in a soft downward curve just below the section title.
          // Uses the light pastel pair (not the fully-saturated brand
          // colors) so the logo and dark title text underneath stay legible
          // without needing to flip everything to white text.
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: const _CurvedHeaderClipper(),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.accentLight],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 44),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => context.go('/search'),
                            ),
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
                        Image.asset('assets/logos/logo-long.png', height: 72, fit: BoxFit.contain),
                        if (user != null) ...[
                          const SizedBox(height: 4),
                          Text('Hi, ${user.displayName}!', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                        const SizedBox(height: 16),

                        // Meal-type quick-filter chips — a faster filter for
                        // what a parent needs right now than browsing by
                        // cuisine, which still lives in Search's full filter
                        // panel.
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: AppConstants.mealCategories.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              if (i == 0) {
                                final isAll = filter.mealCategories.isEmpty;
                                return FilterChip(
                                  label: const Text('All'),
                                  selected: isAll,
                                  backgroundColor: AppColors.surface,
                                  onSelected: (_) => ref
                                      .read(recipeFilterProvider.notifier)
                                      .update((f) => f.copyWith(mealCategories: [])),
                                );
                              }
                              final mealType = AppConstants.mealCategories[i - 1];
                              final selected = filter.mealCategories.contains(mealType);
                              // Each unselected meal-type chip cycles through
                              // the brand pastel fills instead of one flat
                              // neutral tone, so this row reads as more
                              // colorful at a glance.
                              return FilterChip(
                                label: Text(mealType),
                                selected: selected,
                                backgroundColor: AppColors.pastelFills[(i - 1) % AppColors.pastelFills.length],
                                onSelected: (v) {
                                  final updated = selected
                                      ? (List.of(filter.mealCategories)..remove(mealType))
                                      : [...filter.mealCategories, mealType];
                                  ref.read(recipeFilterProvider.notifier).update((f) => f.copyWith(mealCategories: updated));
                                },
                              );
                            },
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

                        // Section header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Expanded so the title wraps within its own
                            // space instead of crowding (or overflowing
                            // past) the Clear button once multiple filters
                            // are active and it shows up.
                            Expanded(
                              child: Text('Recipes parents like you are sharing', style: Theme.of(context).textTheme.headlineSmall),
                            ),
                            if (filter.hasActiveFilters)
                              TextButton(
                                onPressed: () => ref.read(recipeFilterProvider.notifier).update((_) => RecipeFilter.empty),
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Recipe grid
          recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyView(
                    message: 'No recipes found',
                    subMessage: 'Try different filters or check back later.',
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
                onRetry: () => ref.invalidate(recipeListProvider),
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

// Soft downward-bulging curve on the bottom edge of the header gradient,
// same wave-header shape used across many social/parenting apps.
class _CurvedHeaderClipper extends CustomClipper<Path> {
  const _CurvedHeaderClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(size.width / 2, size.height + 24, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
