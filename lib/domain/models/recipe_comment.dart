import 'package:equatable/equatable.dart';

class RecipeComment extends Equatable {
  final String id;
  final String recipeId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final String? parentCommentId;
  final bool isDeleted;
  final bool isHidden;
  final int likeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RecipeComment({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    this.parentCommentId,
    this.isDeleted = false,
    this.isHidden = false,
    this.likeCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) => RecipeComment(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        body: json['body'] as String,
        parentCommentId: json['parentCommentId'] as String?,
        isDeleted: (json['isDeleted'] as bool?) ?? false,
        isHidden: (json['isHidden'] as bool?) ?? false,
        likeCount: (json['likeCount'] as int?) ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'body': body,
        'parentCommentId': parentCommentId,
        'isDeleted': isDeleted,
        'isHidden': isHidden,
        'likeCount': likeCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, body, updatedAt];
}

class RecipeFeedback extends Equatable {
  final String id;
  final String recipeId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final int rating;
  final bool triedIt;
  final String? babyReaction;
  final String? modifications;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RecipeFeedback({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.rating,
    this.triedIt = false,
    this.babyReaction,
    this.modifications,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory RecipeFeedback.fromJson(Map<String, dynamic> json) => RecipeFeedback(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        rating: json['rating'] as int,
        triedIt: (json['triedIt'] as bool?) ?? false,
        babyReaction: json['babyReaction'] as String?,
        modifications: json['modifications'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'rating': rating,
        'triedIt': triedIt,
        'babyReaction': babyReaction,
        'modifications': modifications,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, rating, updatedAt];
}

class RecipeQuestion extends Equatable {
  final String id;
  final String recipeId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String question;
  final bool isAnsweredByCreator;
  final String? creatorAnswer;
  final DateTime? answeredAt;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RecipeQuestion({
    required this.id,
    required this.recipeId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.question,
    this.isAnsweredByCreator = false,
    this.creatorAnswer,
    this.answeredAt,
    this.isHidden = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory RecipeQuestion.fromJson(Map<String, dynamic> json) => RecipeQuestion(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        authorAvatarUrl: json['authorAvatarUrl'] as String?,
        question: json['question'] as String,
        isAnsweredByCreator: (json['isAnsweredByCreator'] as bool?) ?? false,
        creatorAnswer: json['creatorAnswer'] as String?,
        answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt'] as String) : null,
        isHidden: (json['isHidden'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatarUrl': authorAvatarUrl,
        'question': question,
        'isAnsweredByCreator': isAnsweredByCreator,
        'creatorAnswer': creatorAnswer,
        'answeredAt': answeredAt?.toIso8601String(),
        'isHidden': isHidden,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, question, updatedAt];
}

class RecipeReport extends Equatable {
  final String id;
  final String recipeId;
  final String? commentId;
  final String? questionId;
  final String reporterId;
  final String reason;
  final String? details;
  final String status;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  const RecipeReport({
    required this.id,
    required this.recipeId,
    this.commentId,
    this.questionId,
    required this.reporterId,
    required this.reason,
    this.details,
    this.status = 'PENDING',
    this.reviewedBy,
    required this.createdAt,
    this.reviewedAt,
  });

  factory RecipeReport.fromJson(Map<String, dynamic> json) => RecipeReport(
        id: json['id'] as String,
        recipeId: json['recipeId'] as String,
        commentId: json['commentId'] as String?,
        questionId: json['questionId'] as String?,
        reporterId: json['reporterId'] as String,
        reason: json['reason'] as String,
        details: json['details'] as String?,
        status: (json['status'] as String?) ?? 'PENDING',
        reviewedBy: json['reviewedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'commentId': commentId,
        'questionId': questionId,
        'reporterId': reporterId,
        'reason': reason,
        'details': details,
        'status': status,
        'reviewedBy': reviewedBy,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, status];
}
