import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../domain/models/child.dart';
import '../../../domain/models/child_folder_entry.dart';
import '../../../domain/models/recipe.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/recipe_provider.dart';
import '../../recipe/widgets/recipe_row_card.dart';

class SavedRecipesScreen extends ConsumerWidget {
  final bool embedded;
  const SavedRecipesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedRecipesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final hasChildren = (userAsync.valueOrNull?.children.isNotEmpty) ?? false;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        userAsync.when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Children', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ...user.children.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ChildFoldersSection(child: c),
                    )),
                OutlinedButton.icon(
                  onPressed: () => _showAddOrEditChild(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Add child'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Text('Saved recipes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        savedAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: EmptyView(
                  message: 'No saved recipes yet',
                  subMessage: 'Tap the bookmark icon on any recipe to save it here.',
                  icon: Icons.bookmark_outline,
                ),
              );
            }
            // No children yet, so there's no per-child folder browsing —
            // give these recipes the same folder-style organization,
            // grouped by the recipe's own meal-type tags instead.
            if (!hasChildren) return _MealTypeFoldersSection(recipes: recipes);
            return Column(
              children: recipes
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RecipeRowCard(
                          recipe: r,
                          onTap: () => context.push('/recipe/${r.id}'),
                          trailing: _RemoveButton(recipe: r),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(savedRecipesProvider)),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved recipes')),
      body: body,
    );
  }
}

void _showAddOrEditChild(BuildContext context, WidgetRef ref, {Child? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _AddEditChildSheet(existing: existing),
  );
}

Future<void> _confirmRemoveChild(BuildContext context, WidgetRef ref, Child child) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove child?'),
      content: Text('"${child.name}" and their saved-recipe folders will be removed.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
      ],
    ),
  );
  if (confirmed != true) return;

  final result = await ref.read(authRepositoryProvider).removeChild(child.id);
  if (!context.mounted) return;
  result.when(
    success: (_) {
      ref.read(currentUserProvider.notifier).refresh();
      ref.invalidate(childFolderEntriesProvider(child.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Child removed.')));
    },
    failure: (e) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not remove child: ${e.message}'), backgroundColor: AppColors.error),
    ),
  );
}

// A child's name/age header plus their four fixed, collapsible recipe
// folders (4.4) — each shows its saved-item count and expands to reveal
// the recipes, matching the existing bookmark-remove pattern.
class _ChildFoldersSection extends ConsumerWidget {
  final Child child;
  const _ChildFoldersSection({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(childFolderEntriesProvider(child.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(Icons.child_care)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(child.ageLabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAddOrEditChild(context, ref, existing: child);
                    } else if (value == 'delete') {
                      _confirmRemoveChild(context, ref, child);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            entriesAsync.when(
              data: (entries) {
                final byFolder = <String, List<ChildRecipeFolderEntry>>{
                  for (final f in AppConstants.recipeFolders) f: [],
                };
                for (final e in entries) {
                  (byFolder[e.folder] ??= []).add(e);
                }
                return Column(
                  children: AppConstants.recipeFolders.map((folder) {
                    final items = byFolder[folder] ?? const [];
                    return ExpansionTile(
                      title: Text(
                        '$folder (${items.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      children: items.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'No recipes saved to $folder yet.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ]
                          : items
                              .map((entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: RecipeRowCard(
                                      recipe: entry.recipe!,
                                      onTap: () => context.push('/recipe/${entry.recipeId}'),
                                      trailing: _RemoveFromFolderButton(entry: entry),
                                    ),
                                  ))
                              .toList(),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Could not load folders: $e', style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Groups the flat Saved Recipes list into collapsible meal-type folders,
// shown instead of the plain list when the user has no children — gives
// them the same folder-style browsing the per-child section offers,
// keyed off each recipe's own mealCategories tags rather than a child's
// hand-picked folder. A recipe can appear under more than one folder if
// it's tagged with more than one meal category; untagged recipes land
// in "Other".
class _MealTypeFoldersSection extends StatelessWidget {
  final List<Recipe> recipes;
  const _MealTypeFoldersSection({required this.recipes});

  @override
  Widget build(BuildContext context) {
    const categories = [...AppConstants.mealCategories, 'Other'];
    final byCategory = <String, List<Recipe>>{for (final c in categories) c: []};
    for (final r in recipes) {
      if (r.mealCategories.isEmpty) {
        byCategory['Other']!.add(r);
      } else {
        for (final c in r.mealCategories) {
          (byCategory[c] ??= []).add(r);
        }
      }
    }
    return Column(
      children: categories.map((category) {
        final items = byCategory[category] ?? const [];
        return ExpansionTile(
          title: Text(
            '$category (${items.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No saved recipes in $category yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ]
              : items
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RecipeRowCard(
                          recipe: r,
                          onTap: () => context.push('/recipe/${r.id}'),
                          trailing: _RemoveButton(recipe: r),
                        ),
                      ))
                  .toList(),
        );
      }).toList(),
    );
  }
}

class _AddEditChildSheet extends ConsumerStatefulWidget {
  final Child? existing;
  const _AddEditChildSheet({this.existing});

  @override
  ConsumerState<_AddEditChildSheet> createState() => _AddEditChildSheetState();
}

class _AddEditChildSheetState extends ConsumerState<_AddEditChildSheet> {
  late final TextEditingController _nameCtrl;
  DateTime? _birthdate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _birthdate = widget.existing?.birthdate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      helpText: "Child's birthdate",
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _birthdate == null) {
      // A SnackBar here shows on the screen behind this modal sheet, not
      // visibly on top of it — inline text is the only reliable way to
      // surface this without the sheet appearing to just do nothing.
      setState(() => _error = 'Enter a name and select a birthdate.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final repo = ref.read(authRepositoryProvider);
    final result = widget.existing != null
        ? await repo.updateChild(Child(id: widget.existing!.id, name: name, birthdate: _birthdate!, createdAt: widget.existing!.createdAt))
        : await repo.addChild(name, _birthdate!);
    if (!mounted) return;
    await result.when(
      // Awaiting the refresh before popping keeps the provider-driven
      // router rebuild and this sheet's own Navigator.pop from landing in
      // the same frame — doing both at once was tripping GoRouter's
      // duplicate-page-key assertion and crashing the app.
      success: (_) async {
        await ref.read(currentUserProvider.notifier).refresh();
        if (mounted) Navigator.pop(context);
      },
      failure: (e) async {
        setState(() { _saving = false; _error = 'Could not save: ${e.message}'; });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.existing != null ? 'Edit child' : 'Add child', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          AppTextField(controller: _nameCtrl, label: "Child's name"),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickBirthdate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birthdate',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(
                _birthdate == null
                    ? 'Tap to select a date'
                    : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                style: _birthdate == null
                    ? TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
                    : null,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Lets a member unsave a recipe directly from the list, without having to
// open its detail page first.
class _RemoveButton extends ConsumerStatefulWidget {
  final Recipe recipe;
  const _RemoveButton({required this.recipe});

  @override
  ConsumerState<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends ConsumerState<_RemoveButton> {
  bool _removing = false;

  Future<void> _remove() async {
    setState(() => _removing = true);
    final result = await ref.read(recipeRepositoryProvider).unsaveRecipe(widget.recipe.id);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(savedRecipesProvider);
        ref.invalidate(isRecipeSavedProvider(widget.recipe.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved recipes')),
        );
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: ${e.message}'), backgroundColor: AppColors.error),
        );
        setState(() => _removing = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _removing
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : IconButton(
            icon: const Icon(Icons.bookmark_remove_outlined, color: AppColors.textSecondary, size: 20),
            tooltip: 'Remove from saved',
            onPressed: _remove,
          );
  }
}

class _RemoveFromFolderButton extends ConsumerStatefulWidget {
  final ChildRecipeFolderEntry entry;
  const _RemoveFromFolderButton({required this.entry});

  @override
  ConsumerState<_RemoveFromFolderButton> createState() => _RemoveFromFolderButtonState();
}

class _RemoveFromFolderButtonState extends ConsumerState<_RemoveFromFolderButton> {
  bool _removing = false;

  Future<void> _remove() async {
    setState(() => _removing = true);
    final entry = widget.entry;
    final result = await ref
        .read(recipeRepositoryProvider)
        .removeFromChildFolder(entry.childId, entry.folder, entry.recipeId);
    if (!mounted) return;
    result.when(
      success: (_) {
        ref.invalidate(childFolderEntriesProvider(entry.childId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed from ${entry.folder}')),
        );
      },
      failure: (e) {
        setState(() => _removing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove: ${e.message}'), backgroundColor: AppColors.error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _removing
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
            tooltip: 'Remove from folder',
            onPressed: _remove,
          );
  }
}
