import 'notification_preferences_model.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.provider,
    this.avatarUrl,
    required this.role,
    this.createdAt,
    required this.notificationPreferences,
    required this.savedArticlesCount,
    required this.likesCount,
    required this.commentsCount,
  });

  final int id;
  final String name;
  final String email;
  final String? provider;
  final String? avatarUrl;
  final String role;
  final DateTime? createdAt;
  final NotificationPreferencesModel notificationPreferences;
  final int savedArticlesCount;
  final int likesCount;
  final int commentsCount;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      provider: json['provider']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: (json['role'] ?? 'user').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      notificationPreferences: NotificationPreferencesModel.fromJson(
        Map<String, dynamic>.from(
            (json['notification_preferences'] ?? <String, dynamic>{}) as Map),
      ),
      savedArticlesCount:
          int.tryParse((json['saved_articles_count'] ?? 0).toString()) ?? 0,
      likesCount: int.tryParse((json['likes_count'] ?? 0).toString()) ?? 0,
      commentsCount:
          int.tryParse((json['comments_count'] ?? 0).toString()) ?? 0,
    );
  }
}
