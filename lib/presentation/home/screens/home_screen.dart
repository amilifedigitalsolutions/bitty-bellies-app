import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_view.dart';
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
    final recipesAsync = ref.watch(homeRecommendedRecipesProvider);
    final mealWindow = ref.watch(currentMealWindowProvider);

    // Re-measure whenever content that can change the header's height
    // changes (greeting appearing/disappearing).
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
              // PhysicalShape defaults to clipBehavior: Clip.none, which
              // only shapes the drop shadow — the child still paints as a
              // plain rectangle on top and fully hides the curve. This is
              // the actual fix that makes the curve appear at all, not
              // just cast a curved shadow under a flat header.
              clipBehavior: Clip.antiAlias,
              color: AppColors.secondaryLight,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              child: Container(
                width: double.infinity,
                color: AppColors.secondaryLight,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small corner wordmark instead of a big centered
                        // logo — parenting apps (Peanut, Huckleberry,
                        // BabyCenter, the Muna reference) keep branding
                        // small and let the personal greeting carry the
                        // header, since the app reads as "for you and your
                        // kid" rather than as a brand showcase.
                        Row(
                          children: [
                            // White backdrop chip behind the wordmark — the
                            // logo's baby illustration is skin/cream toned
                            // and disappears against the gold header
                            // without it.
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
                        const SizedBox(height: 8),
                        Text(
                          user != null
                              ? '${mealWindow.label} on your mind, ${user.displayName.split(' ').first}?'
                              : '${mealWindow.label} on your mind?',
                          // Lighter than the theme's default headlineLarge
                          // weight (w800) — still reads as a hero line at
                          // this size without looking shouty.
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        // Tap-through search bar — replaces the old
                        // meal-type filter pills. Browsing/filtering now
                        // lives entirely on Search; Home's recipe list
                        // below is auto-filtered by the current meal
                        // window instead of manual pill taps.
                        Material(
                          color: AppColors.surface,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppColors.textSecondary),
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

                        // Section header — no more Clear button here, since
                        // this list is auto-filtered by the current meal
                        // window rather than manual pill selection.
                        Text(
                          '${mealWindow.label} recipes other parents are loving',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
    // Tightened alongside the shorter bottom padding (76 -> 40) so the
    // curve's flat corners sit right after the content instead of leaving
    // a big block of plain gold below it; still a clearly visible scoop.
    return Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(size.width / 2, size.height + 36, size.width, size.height - 36)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
