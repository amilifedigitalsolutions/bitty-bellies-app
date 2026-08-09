import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../domain/models/recipe.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/recipe_provider.dart';

class UploadRecipeScreen extends ConsumerStatefulWidget {
  final Recipe? existingRecipe;
  const UploadRecipeScreen({super.key, this.existingRecipe});

  @override
  ConsumerState<UploadRecipeScreen> createState() => _UploadRecipeScreenState();
}

class _UploadRecipeScreenState extends ConsumerState<UploadRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isSaving = false;

  // Page 1 — Basics
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;
  late final TextEditingController _servingsCtrl;
  File? _coverImage;

  // Page 2 — Classification
  late String _selectedAgeStage;
  late String _selectedTexture;
  late String _selectedCuisine;
  // Free-text cuisine when the fixed list doesn't have one that fits —
  // stored directly as the recipe's cuisine value (not literally "Other"),
  // so it round-trips as a normal string with no schema change needed.
  late final TextEditingController _customCuisineCtrl;
  late final TextEditingController _cultureCtrl;
  late List<String> _selectedMealCategories;
  late List<String> _selectedDietTypes;
  late List<String> _selectedAllergens;
  bool _noAllergensConfirmed = false;

  // Page 3 — Ingredients
  late List<RecipeIngredient> _ingredients;

  // Page 4 — Steps
  late List<RecipeStep> _steps;

  // Page 5 — Safety & Notes
  late final TextEditingController _chokingCtrl;
  late final TextEditingController _safetyCtrl;
  late final TextEditingController _storageCtrl;
  late final TextEditingController _creatorNotesCtrl;

  static const int _totalPages = 5;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecipe;
    _titleCtrl = TextEditingController(text: r?.title ?? '');
    _descriptionCtrl = TextEditingController(text: r?.description ?? '');
    _prepCtrl = TextEditingController(text: '${r?.prepTimeMinutes ?? 10}');
    _cookCtrl = TextEditingController(text: '${r?.cookTimeMinutes ?? 15}');
    _servingsCtrl = TextEditingController(text: '${r?.servings ?? 1}');
    _selectedAgeStage = r?.ageStage ?? AppConstants.ageStages.first;
    _selectedTexture = r?.texture ?? AppConstants.textures.first;
    // An existing recipe's cuisine might itself be a previously-typed custom
    // value that isn't in the fixed list — DropdownButton asserts its value
    // must match one of its items, so that has to map to 'Other' plus a
    // pre-filled custom field rather than being passed through as-is.
    final isCustomCuisine = r != null && !AppConstants.cuisines.contains(r.cuisine);
    _selectedCuisine = isCustomCuisine ? 'Other' : (r?.cuisine ?? AppConstants.cuisines.first);
    _customCuisineCtrl = TextEditingController(text: isCustomCuisine ? r.cuisine : '');
    _cultureCtrl = TextEditingController(text: r?.cultureRegion ?? '');
    _selectedMealCategories = List.of(r?.mealCategories ?? const []);
    _selectedDietTypes = List.of(r?.dietTypes ?? const []);
    _selectedAllergens = List.of(r?.allergens ?? const []);
    // An existing recipe with an empty allergens list already passed the
    // required-allergens check at its original submission time, so treat
    // it as already-confirmed rather than forcing the user to re-toggle it.
    _noAllergensConfirmed = r != null && r.allergens.isEmpty;
    _ingredients = r != null && r.ingredients.isNotEmpty
        ? List.of(r.ingredients)
        : [const RecipeIngredient(name: '', quantity: '')];
    _steps = r != null && r.steps.isNotEmpty
        ? List.of(r.steps)
        : [const RecipeStep(stepNumber: 1, instruction: '')];
    _chokingCtrl = TextEditingController(text: r?.chokingHazardNotes ?? '');
    _safetyCtrl = TextEditingController(text: r?.safetyNotes ?? '');
    _storageCtrl = TextEditingController(text: r?.storageReheatingNotes ?? '');
    _creatorNotesCtrl = TextEditingController(text: r?.creatorNotes ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    _servingsCtrl.dispose();
    _customCuisineCtrl.dispose();
    _cultureCtrl.dispose();
    _chokingCtrl.dispose();
    _safetyCtrl.dispose();
    _storageCtrl.dispose();
    _creatorNotesCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (!_validateCurrentPage()) return;
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _submit();
    }
  }

  // Gates "Next" on the current page's required fields, so a page is never
  // left half-filled — final submission still re-checks everything (see
  // _submit), but this catches it immediately instead of only at the end.
  // "Save draft" bypasses this entirely (it doesn't call _nextPage), since a
  // draft is intentionally allowed to be incomplete.
  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) {
          _showPageError('Recipe title is required.');
          return false;
        }
        if (_descriptionCtrl.text.trim().isEmpty) {
          _showPageError('Short description is required.');
          return false;
        }
        return true;
      case 1:
        if (_selectedCuisine == 'Other' && _customCuisineCtrl.text.trim().isEmpty) {
          _showPageError('Enter your cuisine, or choose one from the list.');
          return false;
        }
        if (_selectedAllergens.isEmpty && !_noAllergensConfirmed) {
          _showPageError('Select any allergens present, or confirm "None of these" applies.');
          return false;
        }
        return true;
      case 2:
        if (_ingredients.where((i) => i.name.trim().isNotEmpty).isEmpty) {
          _showPageError('Add at least one ingredient.');
          return false;
        }
        return true;
      case 3:
        if (_steps.where((s) => s.instruction.trim().isNotEmpty).isEmpty) {
          _showPageError('Add at least one instruction step.');
          return false;
        }
        return true;
      case 4:
        if (_chokingCtrl.text.trim().isEmpty) {
          _showPageError('Describe any choking hazards, or write "None".');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showPageError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _coverImage = File(img.path));
  }

  Future<void> _submit({bool draft = false}) async {
    if (!_formKey.currentState!.validate()) return;
    // Title/description are covered by Form validators above, but ingredients
    // and steps are lists rather than a single text field, and _submit()
    // silently drops blank-name/blank-instruction entries before building
    // the Recipe — so a page left with only the default empty row passes
    // Form validation yet would submit with zero real content. Checked
    // manually here, against the same filtered content that gets submitted.
    if (_ingredients.where((i) => i.name.trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient.')),
      );
      setState(() => _currentPage = 2);
      _pageCtrl.jumpToPage(2);
      return;
    }
    if (_steps.where((s) => s.instruction.trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one instruction step.')),
      );
      setState(() => _currentPage = 3);
      _pageCtrl.jumpToPage(3);
      return;
    }
    // Allergens and choking-hazard notes are safety-review fields that
    // must be consciously addressed before a real submission — but not
    // for a draft, which is an intentionally incomplete work-in-progress.
    // Allergens isn't a single text field, so Form validation can't cover
    // it; choking-hazard notes could use a Form validator, but that would
    // also block drafts, so both are checked manually here instead.
    if (!draft) {
      if (_selectedAllergens.isEmpty && !_noAllergensConfirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select any allergens present, or confirm "None of these" applies.')),
        );
        setState(() => _currentPage = 1);
        _pageCtrl.jumpToPage(1);
        return;
      }
      if (_chokingCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Describe any choking hazards, or write "None".')),
        );
        setState(() => _currentPage = 4);
        _pageCtrl.jumpToPage(4);
        return;
      }
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);

    final recipeId = widget.existingRecipe?.id ?? const Uuid().v4();
    // Editing without picking a new photo keeps whatever media the recipe
    // already had — only replace it if the user actually chose a new file.
    List<RecipeMedia> media = widget.existingRecipe?.media ?? const [];
    if (_coverImage != null) {
      final mediaId = const Uuid().v4();
      final key = 'public/recipes/$recipeId/$mediaId.jpg';
      try {
        await Amplify.Storage.uploadFile(
          localFile: AWSFile.fromPath(_coverImage!.path),
          path: StoragePath.fromString(key),
        ).result;
        media = [
          RecipeMedia(
            id: mediaId,
            recipeId: recipeId,
            s3Key: key,
            url: 'https://${AppConstants.s3MediaBucket}.s3.${AppConstants.s3MediaRegion}.amazonaws.com/$key',
            isCover: true,
            uploadedBy: user.id,
            createdAt: DateTime.now().toUtc(),
          ),
        ];
      } on StorageException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: ${e.message}'), backgroundColor: AppColors.error),
        );
        setState(() => _isSaving = false);
        return;
      }
    }

    final existing = widget.existingRecipe;
    // Editing an already-submitted recipe keeps its current status as-is
    // (no re-triggering review, no accidental demotion via "Save draft") —
    // only a recipe that's still a draft respects the draft/submit toggle.
    final status = existing != null && existing.status != AppConstants.statusDraft
        ? existing.status
        : (draft ? AppConstants.statusDraft : AppConstants.statusPending);

    final recipe = Recipe(
      id: recipeId,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      creatorId: existing?.creatorId ?? user.id,
      creatorName: existing?.creatorName ?? user.displayName,
      ingredients: _ingredients.where((i) => i.name.isNotEmpty).toList(),
      steps: _steps.where((s) => s.instruction.isNotEmpty).toList(),
      media: media,
      prepTimeMinutes: int.tryParse(_prepCtrl.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookCtrl.text) ?? 0,
      servings: int.tryParse(_servingsCtrl.text),
      ageStage: _selectedAgeStage,
      texture: _selectedTexture,
      cuisine: _selectedCuisine == 'Other' ? _customCuisineCtrl.text.trim() : _selectedCuisine,
      cultureRegion: _cultureCtrl.text.trim().isEmpty ? null : _cultureCtrl.text.trim(),
      mealCategories: _selectedMealCategories,
      dietTypes: _selectedDietTypes,
      allergens: _selectedAllergens,
      chokingHazardNotes: _chokingCtrl.text.trim().isEmpty ? null : _chokingCtrl.text.trim(),
      safetyNotes: _safetyCtrl.text.trim().isEmpty ? null : _safetyCtrl.text.trim(),
      storageReheatingNotes: _storageCtrl.text.trim().isEmpty ? null : _storageCtrl.text.trim(),
      creatorNotes: _creatorNotesCtrl.text.trim().isEmpty ? null : _creatorNotesCtrl.text.trim(),
      status: status,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    final repo = ref.read(recipeRepositoryProvider);
    final result = existing != null ? await repo.updateRecipe(recipe) : await repo.createRecipe(recipe);
    if (!mounted) return;

    result.when(
      success: (r) {
        ref.invalidate(recipeSearchProvider);
        ref.invalidate(myRecipesProvider);
        if (existing != null) ref.invalidate(recipeDetailProvider(recipeId));
        final message = existing != null
            ? 'Recipe updated.'
            : (draft ? 'Recipe saved as draft.' : 'Recipe submitted for review!');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        if (existing != null) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      failure: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: AppColors.error),
        );
      },
    );

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecipe != null ? 'Edit recipe' : 'Share a recipe'),
        leading: _currentPage == 0
            ? const BackButton()
            : IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevPage),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _submit(draft: true),
            child: const Text('Save draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress bar — rounded pill instead of the default flat bar,
            // matching the rounded language used everywhere else.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / _totalPages,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('Step ${_currentPage + 1} of $_totalPages', style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  Text(_pageTitle(_currentPage), style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _BasicsPage(
                    titleCtrl: _titleCtrl,
                    descriptionCtrl: _descriptionCtrl,
                    prepCtrl: _prepCtrl,
                    cookCtrl: _cookCtrl,
                    servingsCtrl: _servingsCtrl,
                    coverImage: _coverImage,
                    onPickImage: _pickImage,
                  ),
                  _ClassificationPage(
                    selectedAgeStage: _selectedAgeStage,
                    selectedTexture: _selectedTexture,
                    selectedCuisine: _selectedCuisine,
                    customCuisineCtrl: _customCuisineCtrl,
                    cultureCtrl: _cultureCtrl,
                    selectedMealCategories: _selectedMealCategories,
                    selectedDietTypes: _selectedDietTypes,
                    selectedAllergens: _selectedAllergens,
                    noAllergensConfirmed: _noAllergensConfirmed,
                    onAgeStageChanged: (v) => setState(() => _selectedAgeStage = v),
                    onTextureChanged: (v) => setState(() => _selectedTexture = v),
                    onCuisineChanged: (v) => setState(() => _selectedCuisine = v),
                    onMealCategoryToggle: (v, sel) => setState(() {
                      if (sel) _selectedMealCategories.add(v); else _selectedMealCategories.remove(v);
                    }),
                    onDietToggle: (v, sel) => setState(() {
                      if (sel) _selectedDietTypes.add(v); else _selectedDietTypes.remove(v);
                    }),
                    onAllergenToggle: (v, sel) => setState(() {
                      if (sel) {
                        _selectedAllergens.add(v);
                        _noAllergensConfirmed = false;
                      } else {
                        _selectedAllergens.remove(v);
                      }
                    }),
                    onNoAllergensToggle: (v) => setState(() {
                      _noAllergensConfirmed = v;
                      if (v) _selectedAllergens.clear();
                    }),
                  ),
                  _IngredientsPage(
                    ingredients: _ingredients,
                    onAdd: () => setState(() => _ingredients.add(RecipeIngredient(name: '', quantity: '', unit: null))),
                    onRemove: (i) => setState(() => _ingredients.removeAt(i)),
                    onUpdate: (i, ing) => setState(() => _ingredients[i] = ing),
                  ),
                  _StepsPage(
                    steps: _steps,
                    onAdd: () => setState(() => _steps.add(RecipeStep(stepNumber: _steps.length + 1, instruction: ''))),
                    onRemove: (i) => setState(() {
                      _steps.removeAt(i);
                      for (var j = i; j < _steps.length; j++) {
                        _steps[j] = RecipeStep(stepNumber: j + 1, instruction: _steps[j].instruction, tip: _steps[j].tip);
                      }
                    }),
                    onUpdate: (i, s) => setState(() => _steps[i] = s),
                  ),
                  _SafetyPage(
                    chokingCtrl: _chokingCtrl,
                    safetyCtrl: _safetyCtrl,
                    storageCtrl: _storageCtrl,
                    creatorNotesCtrl: _creatorNotesCtrl,
                  ),
                ],
              ),
            ),

            // Bottom navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _nextPage,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_currentPage == _totalPages - 1 ? 'Submit for review' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageTitle(int page) => switch (page) {
        0 => 'Basic info',
        1 => 'Categories',
        2 => 'Ingredients',
        3 => 'Instructions',
        4 => 'Safety & notes',
        _ => '',
      };
}

// ── Page 1: Basics ────────────────────────────────────────────────────────────

class _BasicsPage extends StatelessWidget {
  final TextEditingController titleCtrl, descriptionCtrl, prepCtrl, cookCtrl, servingsCtrl;
  final File? coverImage;
  final VoidCallback onPickImage;

  const _BasicsPage({
    required this.titleCtrl,
    required this.descriptionCtrl,
    required this.prepCtrl,
    required this.cookCtrl,
    required this.servingsCtrl,
    this.coverImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cover image picker
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: coverImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(coverImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text('Add a cover photo (optional)', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: titleCtrl,
            label: 'Recipe title',
            hint: 'e.g. Japanese Sweet Potato Wedges',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: descriptionCtrl,
            label: 'Short description',
            hint: 'What makes this recipe special?',
            maxLines: 3,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: prepCtrl,
                  label: 'Prep time (min)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter minutes' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: cookCtrl,
                  label: 'Cook time (min)',
                  keyboardType: TextInputType.number,
                  validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter minutes' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: servingsCtrl,
                  label: 'Servings',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Classification ────────────────────────────────────────────────────

class _ClassificationPage extends StatelessWidget {
  final String selectedAgeStage, selectedTexture, selectedCuisine;
  final TextEditingController customCuisineCtrl;
  final TextEditingController cultureCtrl;
  final List<String> selectedMealCategories, selectedDietTypes, selectedAllergens;
  final bool noAllergensConfirmed;
  final void Function(String) onAgeStageChanged, onTextureChanged, onCuisineChanged;
  final void Function(String, bool) onMealCategoryToggle, onDietToggle, onAllergenToggle;
  final void Function(bool) onNoAllergensToggle;

  const _ClassificationPage({
    required this.selectedAgeStage,
    required this.selectedTexture,
    required this.selectedCuisine,
    required this.customCuisineCtrl,
    required this.cultureCtrl,
    required this.selectedMealCategories,
    required this.selectedDietTypes,
    required this.selectedAllergens,
    required this.noAllergensConfirmed,
    required this.onAgeStageChanged,
    required this.onTextureChanged,
    required this.onCuisineChanged,
    required this.onMealCategoryToggle,
    required this.onDietToggle,
    required this.onAllergenToggle,
    required this.onNoAllergensToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Dropdown(
            label: 'Suitable age stage',
            value: selectedAgeStage,
            items: AppConstants.ageStages,
            onChanged: onAgeStageChanged,
          ),
          const SizedBox(height: 16),
          _Dropdown(
            label: 'Texture / format',
            value: selectedTexture,
            items: AppConstants.textures,
            onChanged: onTextureChanged,
          ),
          const SizedBox(height: 16),
          _Dropdown(
            label: 'Cuisine',
            value: selectedCuisine,
            items: AppConstants.cuisines,
            onChanged: onCuisineChanged,
          ),
          if (selectedCuisine == 'Other') ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: customCuisineCtrl,
              label: 'What cuisine is it?',
              hint: 'e.g. Ethiopian, Filipino, Uzbek',
            ),
          ],
          const SizedBox(height: 16),
          AppTextField(
            controller: cultureCtrl,
            label: 'Culture / region (optional)',
            hint: 'e.g. West African, Oaxacan, Levantine',
          ),
          const SizedBox(height: 20),

          Text('Meal type', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.mealCategories.map((c) {
              final sel = selectedMealCategories.contains(c);
              return FilterChip(label: Text(c), selected: sel, onSelected: (v) => onMealCategoryToggle(c, v));
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('Diet types', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.dietTypes.map((d) {
              final sel = selectedDietTypes.contains(d);
              return FilterChip(label: Text(d), selected: sel, onSelected: (v) => onDietToggle(d, v));
            }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Text('Allergens in this recipe', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              const Tooltip(
                message: 'Check every allergen in this recipe — it helps other parents keep their kids safe. Required before submitting.',
                child: Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('None of these'),
                selected: noAllergensConfirmed,
                onSelected: onNoAllergensToggle,
              ),
              ...AppConstants.allergens.map((a) {
                final sel = selectedAllergens.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: sel,
                  selectedColor: AppColors.allergenTag,
                  onSelected: (v) => onAllergenToggle(a, v),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String) onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

// ── Page 3: Ingredients ───────────────────────────────────────────────────────

class _IngredientsPage extends StatelessWidget {
  final List<RecipeIngredient> ingredients;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, RecipeIngredient) onUpdate;

  const _IngredientsPage({
    required this.ingredients,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...ingredients.asMap().entries.map((e) {
            final i = e.key;
            final ing = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _IngredientField(
                      title: 'Qty',
                      initialValue: ing.quantity,
                      hintText: '1',
                      onChanged: (v) => onUpdate(i, RecipeIngredient(name: ing.name, quantity: v, unit: ing.unit, notes: ing.notes)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _UnitField(
                      value: ing.unit,
                      onChanged: (v) => onUpdate(i, RecipeIngredient(name: ing.name, quantity: ing.quantity, unit: v, notes: ing.notes)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: _IngredientField(
                      title: 'Ingredient',
                      initialValue: ing.name,
                      hintText: 'Potato',
                      onChanged: (v) => onUpdate(i, RecipeIngredient(name: v, quantity: ing.quantity, unit: ing.unit, notes: ing.notes)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: ingredients.length > 1 ? () => onRemove(i) : null,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add ingredient'),
          ),
        ],
      ),
    );
  }
}

/// Unit picker, styled to match _IngredientField (title fixed above the
/// box). A dropdown rather than free text so units stay consistent across
/// recipes instead of accumulating spelling/abbreviation variants (tsp vs
/// tsp. vs teaspoon). Optional — includes a blank option since not every
/// ingredient needs a unit (e.g. "1 banana").
class _UnitField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _UnitField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String?>(
          initialValue: value != null && AppConstants.units.contains(value) ? value : null,
          decoration: const InputDecoration(hintText: 'tsp', isDense: true),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('—')),
            ...AppConstants.units.map((u) => DropdownMenuItem<String?>(value: u, child: Text(u))),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A field with its title fixed above the box, so the title never competes
/// with typed content or the hint for width — unlike a floating labelText,
/// which shares the box with the value and can get squeezed out.
class _IngredientField extends StatelessWidget {
  final String title;
  final String? initialValue;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _IngredientField({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(hintText: hintText, isDense: true),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Page 4: Steps ─────────────────────────────────────────────────────────────

class _StepsPage extends StatelessWidget {
  final List<RecipeStep> steps;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final void Function(int, RecipeStep) onUpdate;

  const _StepsPage({
    required this.steps,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final step = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Text('${step.stepNumber}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: step.instruction,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Instruction', hintText: 'Describe this step...'),
                          onChanged: (v) => onUpdate(i, RecipeStep(stepNumber: step.stepNumber, instruction: v, tip: step.tip)),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Instruction required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: step.tip,
                          decoration: const InputDecoration(labelText: 'Tip (optional)', hintText: 'e.g. Baby can also hold this as a spear'),
                          onChanged: (v) => onUpdate(i, RecipeStep(stepNumber: step.stepNumber, instruction: step.instruction, tip: v.isEmpty ? null : v)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: steps.length > 1 ? () => onRemove(i) : null,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add step'),
          ),
        ],
      ),
    );
  }
}

// ── Page 5: Safety & Notes ────────────────────────────────────────────────────

class _SafetyPage extends StatelessWidget {
  final TextEditingController chokingCtrl, safetyCtrl, storageCtrl, creatorNotesCtrl;
  const _SafetyPage({
    required this.chokingCtrl,
    required this.safetyCtrl,
    required this.storageCtrl,
    required this.creatorNotesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Safety information helps parents make informed decisions. Please be as specific as possible about any risks.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: chokingCtrl,
            label: 'Choking hazard notes',
            hint: 'e.g. Cut grapes into quarters. Ensure carrots are well cooked. Write "None" if not applicable.',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: safetyCtrl,
            label: 'Safety notes (optional)',
            hint: 'e.g. Test temperature before serving. Suitable for self-feeding.',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: storageCtrl,
            label: 'Storage & reheating (optional)',
            hint: 'e.g. Refrigerate for up to 3 days. Reheat thoroughly before serving.',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: creatorNotesCtrl,
            label: 'Creator notes (optional)',
            hint: 'Any extra tips, variations, or personal story behind this recipe.',
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          Text(
            'By submitting, you confirm this recipe does not contain medical advice and is safe to share with the community.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
