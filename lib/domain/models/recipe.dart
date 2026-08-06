import 'dart:convert';

import 'package:equatable/equatable.dart';

/// AppSync serializes AWSJSON fields as JSON-encoded strings. Seeded data is
/// double-encoded (the DynamoDB attribute already held a stringified array,
/// which AWSJSON then re-stringifies), so decode repeatedly until a list
/// falls out, rather than assuming a single decode.
List<dynamic>? _decodeJsonListField(dynamic value) {
  var current = value;
  for (var i = 0; current is String && i < 3; i++) {
    current = jsonDecode(current);
  }
  if (current == null) return null;
  if (current is List) return current;
  throw FormatException('Unexpected type for AWSJSON list field: ${current.runtimeType}');
}

class RecipeIngredient extends Equatable {
  final String name;
  final String quantity;
  final String? unit;
  final String? notes;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    this.unit,
    this.notes,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
        name: json['name'] as String,
        quantity: json['quantity'] as String,
        unit: json['unit'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'notes': notes,
      };

  @override
  List<Object?> get props => [name, quantity, unit];
}

class RecipeStep extends Equatable {
  final int stepNumber;
  final String instruction;
  final String? tip;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.tip,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNumber: json['stepNumber'] as int,
        instruction: json['instruction'] as String,
        tip: json['tip'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'instruction': instruction,
        'tip': tip,
      };

  @override
  List<Object?> get props => [stepNumber, instruction];
}

class RecipeMedia extends Equatable {
  final String id;
  final String recipeId;
  final String s3Key;
  final String url;
  final String type; // 'image' | 'video'
  final bool isCover;
  final int sortOrder;
  final String uploadedBy;
  final DateTime createdAt;

  const RecipeMedia({
    required this.id,
    required this.recipeId,
    required this.s3Key,
    required this.url,
    this.type = 'image',
    this.isCover = false,
    this.sortOrder = 0,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory RecipeMedia.fromJson(Map<String, dynamic> json) => RecipeMedia(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        s3Key: json['s3Key'] as String,
        url: json['url'] as String,
        type: (json['type'] as String?) ?? 'image',
        isCover: (json['isCover'] as bool?) ?? false,
        sortOrder: (json['sortOrder'] as int?) ?? 0,
        uploadedBy: json['uploadedBy'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        's3Key': s3Key,
        'url': url,
        'type': type,
        'isCover': isCover,
        'sortOrder': sortOrder,
        'uploadedBy': uploadedBy,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [id, s3Key];
}

class Recipe extends Equatable {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatarUrl;

  // Content
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<RecipeMedia> media;

  // Timing
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int? servings;

  // Classification
  final String ageStage;           // e.g. '6 - 12 months'
  final String texture;            // e.g. 'finger food'
  final String cuisine;
  final String? cultureRegion;
  final List<String> mealCategories;
  final List<String> dietTypes;
  final List<String> allergens;    // allergens PRESENT in the recipe

  // Safety
  final String? chokingHazardNotes;
  final String? safetyNotes;
  final String? storageReheatingNotes;
  final String? creatorNotes;

  // Metadata
  final String status; // DRAFT | PENDING_REVIEW | PUBLISHED | REJECTED | REMOVED
  final List<String> tags;
  final int savedCount;
  final int commentCount;
  final int feedbackCount;
  final double? averageRating;

  // Monetization placeholders (all null for MVP)
  final bool isSponsored;
  final String? sponsorId;
  final bool isPremium;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  // Moderation
  final String? moderationNote;
  final String? moderatedBy;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatarUrl,
    this.ingredients = const [],
    this.steps = const [],
    this.media = const [],
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.servings,
    required this.ageStage,
    required this.texture,
    required this.cuisine,
    this.cultureRegion,
    this.mealCategories = const [],
    this.dietTypes = const [],
    this.allergens = const [],
    this.chokingHazardNotes,
    this.safetyNotes,
    this.storageReheatingNotes,
    this.creatorNotes,
    this.status = 'DRAFT',
    this.tags = const [],
    this.savedCount = 0,
    this.commentCount = 0,
    this.feedbackCount = 0,
    this.averageRating,
    this.isSponsored = false,
    this.sponsorId,
    this.isPremium = false,
    required this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.moderationNote,
    this.moderatedBy,
  });

  String? get coverImageUrl {
    final cover = media.where((m) => m.isCover).firstOrNull;
    return cover?.url ?? media.firstOrNull?.url;
  }

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  String get totalTimeLabel {
    final total = totalTimeMinutes;
    if (total < 60) return '${total}m';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  bool get isPublished => status == 'PUBLISHED';

  // Shown on cards/detail for recipes that are visible in the public feed
  // ahead of moderator approval — null once a recipe leaves PENDING_REVIEW.
  String? get pendingLabel => status == 'PENDING_REVIEW' ? 'Pending review' : null;

  // Full recipe content for the share sheet — description, timing,
  // ingredients, and steps, not just the title. share_plus only takes plain
  // text (no rich HTML/markdown), and this app has no public web URL yet to
  // share a link to instead, so the text itself has to be self-contained.
  String get shareText {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln()
      ..writeln(description)
      ..writeln()
      ..writeln('$totalTimeLabel · $ageStage${servings != null ? ' · Serves $servings' : ''}');

    if (ingredients.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Ingredients:');
      for (final i in ingredients) {
        final parts = <String>[
          if (i.quantity.isNotEmpty) i.quantity,
          if (i.unit != null && i.unit!.isNotEmpty) i.unit!,
        ];
        final qty = parts.isEmpty ? '' : '${parts.join(' ')} ';
        final notes = i.notes != null && i.notes!.isNotEmpty ? ' (${i.notes})' : '';
        buffer.writeln('- $qty${i.name}$notes');
      }
    }

    if (steps.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Steps:');
      for (final s in steps) {
        buffer.writeln('${s.stepNumber}. ${s.instruction}');
        if (s.tip != null && s.tip!.isNotEmpty) buffer.writeln('   Tip: ${s.tip}');
      }
    }

    if (allergens.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Contains: ${allergens.join(', ')}');
    }

    buffer
      ..writeln()
      ..write('Shared from Bitty Bellies — real recipes, from real parents, just like you. '
          'Download on the App Store for more smart, kid-friendly recipes from a community '
          'of parents figuring out meals and sharing what worked.');

    return buffer.toString();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        creatorId: json['creatorId'] as String,
        creatorName: json['creatorName'] as String,
        creatorAvatarUrl: json['creatorAvatarUrl'] as String?,
        ingredients: _decodeJsonListField(json['ingredients'])
                ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        steps: _decodeJsonListField(json['steps'])
                ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        media: (json['media'] as List<dynamic>?)
                ?.map((e) => RecipeMedia.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        prepTimeMinutes: (json['prepTimeMinutes'] as int?) ?? 0,
        cookTimeMinutes: (json['cookTimeMinutes'] as int?) ?? 0,
        servings: json['servings'] as int?,
        ageStage: json['ageStage'] as String,
        texture: json['texture'] as String,
        cuisine: json['cuisine'] as String,
        cultureRegion: json['cultureRegion'] as String?,
        mealCategories: List<String>.from(json['mealCategories'] as List? ?? []),
        dietTypes: List<String>.from(json['dietTypes'] as List? ?? []),
        allergens: List<String>.from(json['allergens'] as List? ?? []),
        chokingHazardNotes: json['chokingHazardNotes'] as String?,
        safetyNotes: json['safetyNotes'] as String?,
        storageReheatingNotes: json['storageReheatingNotes'] as String?,
        creatorNotes: json['creatorNotes'] as String?,
        status: (json['status'] as String?) ?? 'DRAFT',
        tags: List<String>.from(json['tags'] as List? ?? []),
        savedCount: (json['savedCount'] as int?) ?? 0,
        commentCount: (json['commentCount'] as int?) ?? 0,
        feedbackCount: (json['feedbackCount'] as int?) ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        isSponsored: (json['isSponsored'] as bool?) ?? false,
        sponsorId: json['sponsorId'] as String?,
        isPremium: (json['isPremium'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
        moderationNote: json['moderationNote'] as String?,
        moderatedBy: json['moderatedBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'creatorAvatarUrl': creatorAvatarUrl,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps.map((e) => e.toJson()).toList(),
        'media': media.map((e) => e.toJson()).toList(),
        'prepTimeMinutes': prepTimeMinutes,
        'cookTimeMinutes': cookTimeMinutes,
        'servings': servings,
        'ageStage': ageStage,
        'texture': texture,
        'cuisine': cuisine,
        'cultureRegion': cultureRegion,
        'mealCategories': mealCategories,
        'dietTypes': dietTypes,
        'allergens': allergens,
        'chokingHazardNotes': chokingHazardNotes,
        'safetyNotes': safetyNotes,
        'storageReheatingNotes': storageReheatingNotes,
        'creatorNotes': creatorNotes,
        'status': status,
        'tags': tags,
        'savedCount': savedCount,
        'commentCount': commentCount,
        'feedbackCount': feedbackCount,
        'averageRating': averageRating,
        'isSponsored': isSponsored,
        'sponsorId': sponsorId,
        'isPremium': isPremium,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'moderationNote': moderationNote,
        'moderatedBy': moderatedBy,
      };

  @override
  List<Object?> get props => [id, title, status, updatedAt];
}
