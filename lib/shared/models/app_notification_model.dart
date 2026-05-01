class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
    this.readAt,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;

  int? get articleId {
    final direct = _asInt(payload['article_id']);
    if (direct != null) return direct;
    return _asInt(payload['wp_article_id']);
  }

  int? get categoryId {
    final direct = _asInt(payload['category_id']);
    if (direct != null) return direct;
    final list = payload['category_ids'];
    if (list is List && list.isNotEmpty) {
      return _asInt(list.first);
    }
    return null;
  }

  int? get breakingNewsId => _asInt(payload['breaking_news_id']);

  String? get screen => payload['screen']?.toString();

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(
      (json['payload'] ?? <String, dynamic>{}) as Map,
    );

    return AppNotificationModel(
      id: _asInt(json['id']) ?? 0,
      title: _sanitizeText(
        json['title'],
        fallback: (payload['title'] ?? 'إشعار جديد').toString(),
      ),
      body: _sanitizeText(
        json['body'],
        fallback: (payload['body'] ?? 'لديك تحديث جديد.').toString(),
      ),
      payload: payload,
      readAt: DateTime.tryParse((json['read_at'] ?? '').toString()),
      createdAt: _parseDate((json['created_at'] ?? '').toString()),
    );
  }

  static DateTime? _parseDate(String raw) {
    final dt = DateTime.tryParse(raw);
    return dt?.toLocal();
  }

  static String _sanitizeText(dynamic value, {required String fallback}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return fallback;

    final questionCount = '?'.allMatches(text).length;
    final replacementCount = '�'.allMatches(text).length;
    final total = questionCount + replacementCount;

    if (total >= (text.length * 0.5).ceil()) {
      return fallback;
    }

    return text;
  }
}
