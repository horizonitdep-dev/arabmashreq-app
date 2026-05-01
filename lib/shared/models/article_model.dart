import '../../core/config/extensions.dart';

class ArticleModel {
  const ArticleModel({
    required this.id,
    required this.title,
    required this.contentHtml,
    required this.excerpt,
    required this.link,
    required this.date,
    required this.authorId,
    required this.categoryIds,
    this.imageUrl,
    this.viewsCount,
    this.galleryImageUrls = const <String>[],
    this.videoEmbedUrls = const <String>[],
  });

  final int id;
  final String title;
  final String contentHtml;
  final String excerpt;
  final String link;
  final DateTime? date;
  final int authorId;
  final List<int> categoryIds;
  final String? imageUrl;
  final int? viewsCount;
  final List<String> galleryImageUrls;
  final List<String> videoEmbedUrls;

  ArticleModel copyWith({
    int? id,
    String? title,
    String? contentHtml,
    String? excerpt,
    String? link,
    DateTime? date,
    int? authorId,
    List<int>? categoryIds,
    String? imageUrl,
    int? viewsCount,
    List<String>? galleryImageUrls,
    List<String>? videoEmbedUrls,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contentHtml: contentHtml ?? this.contentHtml,
      excerpt: excerpt ?? this.excerpt,
      link: link ?? this.link,
      date: date ?? this.date,
      authorId: authorId ?? this.authorId,
      categoryIds: categoryIds ?? this.categoryIds,
      imageUrl: imageUrl ?? this.imageUrl,
      viewsCount: viewsCount ?? this.viewsCount,
      galleryImageUrls: galleryImageUrls ?? this.galleryImageUrls,
      videoEmbedUrls: videoEmbedUrls ?? this.videoEmbedUrls,
    );
  }

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final media = (embedded?['wp:featuredmedia'] as List<dynamic>?)?.firstOrNull
        as Map<String, dynamic>?;

    return ArticleModel(
      id: json['id'] as int? ?? 0,
      title: (json['title']?['rendered'] ?? 'بدون عنوان').toString(),
      contentHtml: (json['content']?['rendered'] ?? '').toString(),
      excerpt: (json['excerpt']?['rendered'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      authorId: json['author'] as int? ?? 0,
      categoryIds: List<int>.from((json['categories'] ?? []) as List<dynamic>),
      imageUrl: media?['source_url']?.toString(),
      viewsCount: _extractViewsCount(json),
      galleryImageUrls: const <String>[],
      videoEmbedUrls: const <String>[],
    );
  }

  static int? _extractViewsCount(Map<String, dynamic> json) {
    const directKeys = <String>[
      'tie_views',
      'views',
      'view_count',
      'post_views',
      'post_view_count',
    ];

    for (final key in directKeys) {
      if (json.containsKey(key)) {
        final parsed = _toInt(json[key]);
        if (parsed != null) return parsed;
      }
    }

    final meta = json['meta'];
    if (meta is Map) {
      for (final key in directKeys) {
        if (meta.containsKey(key)) {
          final parsed = _toInt(meta[key]);
          if (parsed != null) return parsed;
        }
      }
    }

    return _findIntByKey(json, targetKey: 'tie_views');
  }

  static int? _findIntByKey(dynamic value, {required String targetKey}) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        if (key == targetKey ||
            key.endsWith('_$targetKey') ||
            key.contains(targetKey)) {
          final parsed = _toInt(entry.value);
          if (parsed != null) return parsed;
        }
        final nested = _findIntByKey(entry.value, targetKey: targetKey);
        if (nested != null) return nested;
      }
    } else if (value is List) {
      for (final item in value) {
        final nested = _findIntByKey(item, targetKey: targetKey);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    if (value is String) {
      final normalized = _normalizeArabicDigits(value)
          .replaceAll(RegExp(r'[^0-9]'), '')
          .trim();
      if (normalized.isEmpty) return null;
      return int.tryParse(normalized);
    }

    return null;
  }

  static String _normalizeArabicDigits(String input) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const easternIndic = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var out = input;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
      out = out.replaceAll(easternIndic[i], '$i');
    }
    return out;
  }
}
