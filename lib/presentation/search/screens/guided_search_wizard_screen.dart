import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/recipe_filter.dart';
import '../../home/providers/recipe_provider.dart';

// A friendlier, sequential alternative to Search's flat filter panel —
// same underlying RecipeFilter fields, just asked one at a time instead of
// all at once. Age stage is single-choice (a child has one age); the rest
// stay multi-choice since more than one can apply.
class GuidedSearchWizardScreen extends ConsumerStatefulWidget {
  const GuidedSearchWizardScreen({super.key});

  @override
  ConsumerState<GuidedSearchWizardScreen> createState() => _GuidedSearchWizardScreenState();
}

class _GuidedSearchWizardScreenState extends ConsumerState<GuidedSearchWizardScreen> {
  static const _totalSteps = 4;

  int _step = 0;
  String? _ageStage;
  final Set<String> _mealCategories = {};
  final Set<String> _dietTypes = {};
  final Set<String> _allergensToAvoid = {};

  void _finish() {
    ref.read(recipeFilterProvider.notifier).update((_) => RecipeFilter(
          ageStages: _ageStage != null ? [_ageStage!] : const [],
          mealCategories: _mealCategories.toList(),
          dietTypes: _dietTypes.toList(),
          excludeAllergens: _allergensToAvoid.toList(),
        ));
    // go, not pop — this wizard is reached from Home now, so popping would
    // land back on Home instead of showing the results it just built.
    context.go('/search');
  }

  void _advance() {
    if (_step == _totalSteps - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  // Clears the current step's picks before advancing, unlike Next which
  // keeps whatever was already selected.
  void _skip() {
    setState(() {
      switch (_step) {
        case 0:
          _ageStage = null;
          break;
        case 1:
          _mealCategories.clear();
          break;
        case 2:
          _dietTypes.clear();
          break;
        default:
          _allergensToAvoid.clear();
      }
    });
    _advance();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_step + 1} of $_totalSteps'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (_step + 1) / _totalSteps),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: _skip, child: const Text('Skip')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _advance,
                  child: Text(_step == _totalSteps - 1 ? 'Show results' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _SingleChoiceStep(
          title: "How old is your child?",
          options: AppConstants.ageStages,
          selected: _ageStage,
          onSelect: (v) => setState(() => _ageStage = v),
        );
      case 1:
        return _MultiChoiceStep(
          title: 'What meal are you planning?',
          options: AppConstants.mealCategories,
          selected: _mealCategories,
          onToggle: (v) => setState(() => _mealCategories.contains(v) ? _mealCategories.remove(v) : _mealCategories.add(v)),
        );
      case 2:
        return _MultiChoiceStep(
          title: 'Any diet preferences?',
          options: AppConstants.dietTypes,
          selected: _dietTypes,
          onToggle: (v) => setState(() => _dietTypes.contains(v) ? _dietTypes.remove(v) : _dietTypes.add(v)),
        );
      default:
        return _MultiChoiceStep(
          title: 'Avoid any allergens?',
          options: AppConstants.allergens,
          selected: _allergensToAvoid,
          onToggle: (v) =>
              setState(() => _allergensToAvoid.contains(v) ? _allergensToAvoid.remove(v) : _allergensToAvoid.add(v)),
        );
    }
  }
}

class _SingleChoiceStep extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SingleChoiceStep({required this.title, required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((o) => ChoiceChip(
                      label: Text(o),
                      selected: selected == o,
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) => onSelect(o),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MultiChoiceStep extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiChoiceStep({required this.title, required this.options, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((o) => FilterChip(
                      label: Text(o),
                      selected: selected.contains(o),
                      selectedColor: AppColors.primaryLight,
                      onSelected: (_) => onToggle(o),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
