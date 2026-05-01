class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    required this.generalEnabled,
    required this.breakingNewsEnabled,
    required this.preferredCategoryIds,
  });

  final bool generalEnabled;
  final bool breakingNewsEnabled;
  final List<int> preferredCategoryIds;

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['preferred_category_ids'];
    return NotificationPreferencesModel(
      generalEnabled: json['general_enabled'] as bool? ?? true,
      breakingNewsEnabled: json['breaking_news_enabled'] as bool? ?? true,
      preferredCategoryIds: rawCategories is List
          ? rawCategories.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList(growable: false)
          : const <int>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'general_enabled': generalEnabled,
      'breaking_news_enabled': breakingNewsEnabled,
      'preferred_category_ids': preferredCategoryIds,
    };
  }

  NotificationPreferencesModel copyWith({
    bool? generalEnabled,
    bool? breakingNewsEnabled,
    List<int>? preferredCategoryIds,
  }) {
    return NotificationPreferencesModel(
      generalEnabled: generalEnabled ?? this.generalEnabled,
      breakingNewsEnabled: breakingNewsEnabled ?? this.breakingNewsEnabled,
      preferredCategoryIds: preferredCategoryIds ?? this.preferredCategoryIds,
    );
  }

  static const NotificationPreferencesModel defaults = NotificationPreferencesModel(
    generalEnabled: true,
    breakingNewsEnabled: true,
    preferredCategoryIds: <int>[],
  );
}
