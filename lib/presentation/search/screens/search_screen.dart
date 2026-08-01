import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../home/providers/recipe_provider.dart';
import '../../recipe/widgets/recipe_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _updateQuery(String q) {
    final filter = ref.read(recipeFilterProvider);
    ref.read(recipeFilterProvider.notifier).update((_) =>
        q.isEmpty ? filter.copyWith(clearQuery: true) : filter.copyWith(query: q));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(recipeFilterProvider);
    final recipesAsync = ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: true,
        title: Image.asset('assets/logos/logo-long.png', height: 44, fit: BoxFit.contain),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: false,
              onChanged: _updateQuery,
              decoration: InputDecoration(
                hintText: 'Search recipes, ingredients, cultures...',
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _updateQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Flexible (not a bare child) so the filter panel's internal
          // SingleChildScrollView gets a bounded height to scroll within,
          // instead of demanding its full unbounded content height and
          // overflowing the Column once there are enough filter sections
          // to exceed the screen (RenderFlex overflow).
          if (_showFilters) Flexible(child: _FilterPanel(filter: filter)),
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const EmptyView(
                    message: 'No recipes found',
                    subMessage: 'Try adjusting your filters or search terms.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RecipeCard(
                      recipe: recipes[i],
                      onTap: () => context.push('/recipe/${recipes[i].id}'),
                    ),
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: RecipeCardSkeleton(),
                ),
              ),
              error: (e, _) => ErrorView(
                message: 'Search failed. Please try again.',
                onRetry: () => ref.invalidate(recipeListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  final RecipeFilter filter;
  const _FilterPanel({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(RecipeFilter f) => ref.read(recipeFilterProvider.notifier).update((_) => f);
    final cuisines = ref.watch(availableCuisinesProvider).valueOrNull ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterSection(
              title: 'Age stage',
              options: AppConstants.ageStages,
              selected: filter.ageStages,
              onToggle: (v, sel) {
                final l = sel ? [...filter.ageStages, v] : (List.of(filter.ageStages)..remove(v));
                update(filter.copyWith(ageStages: l));
              },
            ),
            _FilterSection(
              title: 'Cuisine',
              options: cuisines,
              selected: filter.cuisines,
              onToggle: (v, sel) {
                final l = sel ? [...filter.cuisines, v] : (List.of(filter.cuisines)..remove(v));
                update(filter.copyWith(cuisines: l));
              },
            ),
            _FilterSection(
              title: 'Meal type',
              options: AppConstants.mealCategories,
              selected: filter.mealCategories,
              onToggle: (v, sel) {
                final l = sel ? [...filter.mealCategories, v] : (List.of(filter.mealCategories)..remove(v));
                update(filter.copyWith(mealCategories: l));
              },
            ),
            _FilterSection(
              title: 'Diet',
              options: AppConstants.dietTypes,
              selected: filter.dietTypes,
              onToggle: (v, sel) {
                final l = sel ? [...filter.dietTypes, v] : (List.of(filter.dietTypes)..remove(v));
                update(filter.copyWith(dietTypes: l));
              },
            ),
            _FilterSection(
              title: 'Texture',
              options: AppConstants.textures,
              selected: filter.textures,
              onToggle: (v, sel) {
                final l = sel ? [...filter.textures, v] : (List.of(filter.textures)..remove(v));
                update(filter.copyWith(textures: l));
              },
            ),
            _FilterSection(
              title: 'Exclude allergens',
              options: AppConstants.allergens,
              selected: filter.excludeAllergens,
              onToggle: (v, sel) {
                final l = sel ? [...filter.excludeAllergens, v] : (List.of(filter.excludeAllergens)..remove(v));
                update(filter.copyWith(excludeAllergens: l));
              },
            ),
            if (filter.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () => update(RecipeFilter.empty),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear all filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selected;
  final void Function(String, bool) onToggle;

  const _FilterSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((o) {
            final sel = selected.contains(o);
            return FilterChip(label: Text(o), selected: sel, onSelected: (v) => onToggle(o, v));
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
