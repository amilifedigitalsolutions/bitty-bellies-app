import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String name;
  final DateTime birthdate;
  final DateTime? createdAt;
  // Diet types (e.g. "Vegetarian", "Dairy-free") and allergens to avoid —
  // same option lists as AppConstants.dietTypes/allergens, so a child's
  // profile can drive RecipeFilter.dietTypes/excludeAllergens directly when
  // "search by child" is used, not just ageStages.
  final List<String> dietTypes;
  final List<String> excludeAllergens;

  const Child({
    required this.id,
    required this.name,
    required this.birthdate,
    this.createdAt,
    this.dietTypes = const [],
    this.excludeAllergens = const [],
  });

  // "8 months" / "2 years" — computed from birthdate rather than stored, so
  // it never goes stale.
  String get ageLabel {
    final months = ageInMonths;
    if (months < 24) {
      return months == 1 ? '1 month' : '$months months';
    }
    final years = months ~/ 12;
    return years == 1 ? '1 year' : '$years years';
  }

  int get ageInMonths {
    final now = DateTime.now();
    var months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
    if (now.day < birthdate.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  // AppConstants.ageStages' lower-bound month threshold, keyed by the exact
  // display strings — a fixed, small list, so a lookup table is more
  // robust than parsing "N - N months"/"N+ months" out of the label text.
  static const Map<String, int> _stageMinMonths = {
    '4 - 6 months': 4,
    '6 - 12 months': 6,
    '12+ months': 12,
  };

  // Every age-stage tag this child is old enough for (i.e. safe to show —
  // a recipe tagged "12+ months" shouldn't surface for a 5-month-old, but a
  // recipe tagged for a younger stage is still fine for an older child).
  // Takes the app's full stage list rather than hardcoding it here, so this
  // stays in sync with AppConstants.
  List<String> matchingAgeStages(List<String> allStages) {
    final months = ageInMonths;
    return allStages.where((s) {
      final min = _stageMinMonths[s];
      return min != null && min <= months;
    }).toList();
  }

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        name: json['name'] as String,
        birthdate: DateTime.parse(json['birthdate'] as String),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        dietTypes: (json['dietTypes'] as List?)?.map((e) => e as String).toList() ?? const [],
        excludeAllergens: (json['excludeAllergens'] as List?)?.map((e) => e as String).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthdate': _dateOnly(birthdate),
        'createdAt': createdAt?.toUtc().toIso8601String(),
        'dietTypes': dietTypes,
        'excludeAllergens': excludeAllergens,
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [id, name, birthdate, dietTypes, excludeAllergens];
}
