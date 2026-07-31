import 'package:equatable/equatable.dart';

class Child extends Equatable {
  final String id;
  final String name;
  final DateTime birthdate;
  final DateTime? createdAt;

  const Child({
    required this.id,
    required this.name,
    required this.birthdate,
    this.createdAt,
  });

  // "8 months" / "2 years" — computed from birthdate rather than stored, so
  // it never goes stale.
  String get ageLabel {
    final now = DateTime.now();
    var months = (now.year - birthdate.year) * 12 + (now.month - birthdate.month);
    if (now.day < birthdate.day) months -= 1;
    if (months < 0) months = 0;
    if (months < 24) {
      return months == 1 ? '1 month' : '$months months';
    }
    final years = months ~/ 12;
    return years == 1 ? '1 year' : '$years years';
  }

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        name: json['name'] as String,
        birthdate: DateTime.parse(json['birthdate'] as String),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthdate': _dateOnly(birthdate),
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [id, name, birthdate];
}
