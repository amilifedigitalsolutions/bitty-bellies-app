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
          // App bar
          SliverAppBar(
            floating: true,
            toolbarHeight: 96,
            centerTitle: true,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logos/logo-long.png', height: 60, fit: BoxFit.contain),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text('Hi, ${user.displayName}!', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
            actions: [
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
              const SizedBox(width: 4),
            ],
          ),

          // Meal-type quick-filter chips — a faster filter for what a
          // parent needs right now (breakfast/lunch/dinner/snack) than
          // browsing by cuisine, which still lives in Search's full filter
          // panel.
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AppConstants.mealCategories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final isAll = filter.mealCategories.isEmpty;
                    return FilterChip(
                      label: const Text('All'),
                      selected: isAll,
                      onSelected: (_) => ref
                          .read(recipeFilterProvider.notifier)
                          .update((f) => f.copyWith(mealCategories: [])),
                    );
                  }
                  final mealType = AppConstants.mealCategories[i - 1];
                  final selected = filter.mealCategories.contains(mealType);
                  return FilterChip(
                    label: Text(mealType),
                    selected: selected,
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
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Safety disclaimer banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.child_care, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Always supervise feeding. These recipes come from parents like you — not medical advice.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Recipes parents like you are sharing', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    TextButton(
                      onPressed: () => ref.read(recipeFilterProvider.notifier).update((_) => RecipeFilter.empty),
                      child: const Text('Clear'),
                    ),
                ],
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
