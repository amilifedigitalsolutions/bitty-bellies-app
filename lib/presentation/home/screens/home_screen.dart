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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _headerKey = GlobalKey();
  // Fixed header stays put while the list scrolls underneath it, so the
  // scroll view needs a top spacer matching the header's real rendered
  // height (it varies with the greeting line, filter chip count, etc.) —
  // measured after the first frame rather than hardcoded.
  double _headerHeight = 340;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  void _measureHeader() {
    final height = _headerKey.currentContext?.size?.height;
    if (height != null && height != _headerHeight && mounted) {
      setState(() => _headerHeight = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final recipesAsync = ref.watch(recipeListProvider);
    final filter = ref.watch(recipeFilterProvider);

    // Re-measure whenever content that can change the header's height
    // changes (greeting appearing/disappearing, Clear button, filters).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());

    return Scaffold(
      body: Stack(
        children: [
          // Recipe list — sits behind the header in the stack, so once a
          // card scrolls up past the header's height it's covered by the
          // (opaque) header drawn on top, i.e. scrolls "under" it.
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: _headerHeight)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

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

          // Curved header — fixed in place while the list above scrolls
          // underneath it. Flat light gold, no gradient.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // PhysicalShape (not plain ClipPath) so the curve casts a real
            // drop shadow along its own silhouette instead of a flat
            // rectangular one, giving the header some lift/dimension off
            // the page.
            child: PhysicalShape(
              key: _headerKey,
              clipper: const _CurvedHeaderClipper(),
              color: AppColors.primary,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 76),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/logos/logo-long.png', height: 32, fit: BoxFit.contain),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white),
                              onPressed: () => context.go('/search'),
                            ),
                            if (user == null)
                              TextButton(
                                onPressed: () => context.push('/login'),
                                child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.bookmark_outline, color: Colors.white),
                                onPressed: () => context.push('/saved'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Big bold greeting is the header's focal point,
                        // matching the reference — the logo shrinks to a
                        // small top-row wordmark instead of the centerpiece.
                        Text(
                          user != null ? 'Hi, ${user.displayName}!' : 'Welcome!',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.appTagline,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                        ),
                        const SizedBox(height: 20),

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
                              // Cycles through blue/purple (not gold — the
                              // header itself is flat gold now, so a gold
                              // chip would be invisible against it) instead
                              // of one flat neutral tone.
                              const chipColors = [AppColors.primaryLight, AppColors.accentLight];
                              return FilterChip(
                                label: Text(mealType),
                                selected: selected,
                                backgroundColor: chipColors[(i - 1) % chipColors.length],
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
                              child: Text(
                                'Recipes parents like you are sharing',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                              ),
                            ),
                            if (filter.hasActiveFilters)
                              TextButton(
                                onPressed: () => ref.read(recipeFilterProvider.notifier).update((_) => RecipeFilter.empty),
                                child: const Text('Clear', style: TextStyle(color: Colors.white)),
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
    // Much deeper swing than the first pass (120px total vs 60px) so the
    // scoop actually reads as a pronounced curve rather than a barely
    // visible dip, matching the reference screenshot.
    return Path()
      ..lineTo(0, size.height - 70)
      ..quadraticBezierTo(size.width / 2, size.height + 50, size.width, size.height - 70)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
