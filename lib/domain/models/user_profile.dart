import 'package:equatable/equatable.dart';
import 'child.dart';

class UserProfile extends Equatable {
  final String id;           // Cognito sub / userId
  final String displayName;
  final String email;
  final String? bio;
  final String? avatarUrl;
  final String? country;
  final String? region;
  final String? culturalBackground; // optional, self-described
  final String? cookingStyle;
  final int savedRecipesCount;
  final int uploadedRecipesCount;
  final bool isVerifiedCreator;
  final bool isModerator;
  final bool isAdmin;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Child> children;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.country,
    this.region,
    this.culturalBackground,
    this.cookingStyle,
    this.savedRecipesCount = 0,
    this.uploadedRecipesCount = 0,
    this.isVerifiedCreator = false,
    this.isModerator = false,
    this.isAdmin = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.children = const [],
  });

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? country,
    String? region,
    String? culturalBackground,
    String? cookingStyle,
    int? savedRecipesCount,
    int? uploadedRecipesCount,
    List<Child>? children,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      region: region ?? this.region,
      culturalBackground: culturalBackground ?? this.culturalBackground,
      cookingStyle: cookingStyle ?? this.cookingStyle,
      savedRecipesCount: savedRecipesCount ?? this.savedRecipesCount,
      uploadedRecipesCount: uploadedRecipesCount ?? this.uploadedRecipesCount,
      isVerifiedCreator: isVerifiedCreator,
      isModerator: isModerator,
      isAdmin: isAdmin,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      children: children ?? this.children,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        country: json['country'] as String?,
        region: json['region'] as String?,
        culturalBackground: json['culturalBackground'] as String?,
        cookingStyle: json['cookingStyle'] as String?,
        savedRecipesCount: (json['savedRecipesCount'] as int?) ?? 0,
        uploadedRecipesCount: (json['uploadedRecipesCount'] as int?) ?? 0,
        isVerifiedCreator: (json['isVerifiedCreator'] as bool?) ?? false,
        isModerator: (json['isModerator'] as bool?) ?? false,
        isAdmin: (json['isAdmin'] as bool?) ?? false,
        isActive: (json['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        children: (json['children'] as List?)
                ?.map((c) => Child.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'country': country,
        'region': region,
        'culturalBackground': culturalBackground,
        'cookingStyle': cookingStyle,
        'savedRecipesCount': savedRecipesCount,
        'uploadedRecipesCount': uploadedRecipesCount,
        'isVerifiedCreator': isVerifiedCreator,
        'isModerator': isModerator,
        'isAdmin': isAdmin,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'children': children.map((c) => c.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, displayName, email];
}
