import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/article_model.dart';
import '../models/author_model.dart';
import '../models/category_model.dart';

class WordpressService {
  WordpressService(this._dio);

  final Dio _dio;

  Future<List<ArticleModel>> fetchLatest({
    int page = 1,
    int perPage = 10,
    int? categoryId,
  }) async {
    final response = await _dio.get('/posts', queryParameters: {
      'page': page,
      'per_page': perPage,
      '_embed': true,
      if (categoryId != null) 'categories': categoryId,
    });

    return (response.data as List<dynamic>)
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response =
        await _dio.get('/categories', queryParameters: {'per_page': 100});
    return (response.data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int?> findCategoryIdByName(String categoryName) async {
    final target = _normalizeArabicText(categoryName);
    if (target.isEmpty) return null;

    try {
      final categories = await fetchCategories();
      for (final category in categories) {
        final current = _normalizeArabicText(category.name);
        if (current == target || current.contains(target)) {
          return category.id;
        }
      }
    } catch (_) {
      // Fall back to direct search request.
    }

    try {
      final response = await _dio.get('/categories', queryParameters: {
        'search': categoryName,
        'per_page': 100,
      });
      final rows = response.data as List<dynamic>;
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final id = row['id'] as int?;
        final name = _normalizeArabicText((row['name'] ?? '').toString());
        if (id != null && (name == target || name.contains(target))) {
          return id;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<ArticleModel> fetchArticle(int articleId) async {
    final response =
        await _dio.get('/posts/$articleId', queryParameters: {'_embed': true});
    final rawData = response.data as Map<String, dynamic>;
    var article = ArticleModel.fromJson(rawData);
    final authorAvatarUrls = _extractAuthorAvatarUrlsFromApiPayload(rawData);

    if (article.contentHtml.trim().isEmpty && article.link.trim().isNotEmpty) {
      final fallback = await _fetchArticleHtmlFallback(article.link);
      if (fallback != null && fallback.trim().isNotEmpty) {
        article = article.copyWith(contentHtml: fallback);
      }
    }

    if (_visibleTextLength(article.contentHtml) < 40 &&
        article.link.trim().isNotEmpty) {
      final fallback = await _fetchArticleHtmlFallback(article.link);
      if (fallback != null && _visibleTextLength(fallback) >= 40) {
        article = article.copyWith(contentHtml: fallback);
      }
    }

    if (_visibleTextLength(article.contentHtml) < 20) {
      final excerpt = (rawData['excerpt']?['rendered'] ?? '').toString();
      if (_visibleTextLength(excerpt) > 0) {
        article = article.copyWith(contentHtml: excerpt);
      }
    }

    var videoUrls = <String>[
      ..._extractVideoUrls(article.contentHtml),
      ..._extractVideoUrlsFromApiPayload(rawData),
    ];

    final imagesFromContent = _extractImageUrls(article.contentHtml);
    final imagesFromPayload = _extractImageUrlsFromApiPayload(rawData);
    final attachmentImages = await _fetchAttachmentImageUrls(article.id);

    var gallery = <String>{
      ...imagesFromContent,
      ...imagesFromPayload,
      ...attachmentImages
    }.where((url) => url.trim().isNotEmpty).toList(growable: false);
    gallery = _removeAuthorAvatarsFromGallery(gallery, authorAvatarUrls);

    videoUrls = _dedupeVideoUrls(videoUrls);

    // Some WordPress themes render extra media only in the public article page HTML.
    if ((gallery.length <= 1 || videoUrls.isEmpty) &&
        article.link.trim().isNotEmpty) {
      final pageContent = await _fetchArticleHtmlFallback(article.link);
      if (pageContent != null && pageContent.trim().isNotEmpty) {
        final pageImages = _extractImageUrls(pageContent);
        final pageVideos = _extractVideoUrls(pageContent);
        gallery = <String>{...gallery, ...pageImages}.toList(growable: false);
        gallery = _removeAuthorAvatarsFromGallery(gallery, authorAvatarUrls);
        videoUrls = _dedupeVideoUrls(<String>[...videoUrls, ...pageVideos]);
      }
    }

    if (kDebugMode) {
      debugPrint(
          '[ARTICLE_MEDIA] id=${article.id} gallery=${gallery.length} videos=${videoUrls.length}');
    }

    final normalizedHtml = _normalizeContentHtml(
      article.contentHtml,
      extractedVideoUrls: videoUrls,
    );

    return article.copyWith(
      contentHtml: normalizedHtml,
      galleryImageUrls: gallery,
      videoEmbedUrls: _dedupeVideoUrls(videoUrls),
    );
  }

  Future<List<ArticleModel>> searchArticles(String query) async {
    final response = await _dio.get('/posts', queryParameters: {
      'search': query,
      '_embed': true,
    });
    return (response.data as List<dynamic>)
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AuthorModel?> fetchAuthor(int id) async {
    if (id <= 0) return null;
    final response = await _dio.get('/users/$id');
    return AuthorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ArticleModel>> relatedByCategory(
      int categoryId, int excludedId) async {
    if (categoryId <= 0) {
      return const <ArticleModel>[];
    }

    try {
      final items =
          await fetchLatest(page: 1, perPage: 8, categoryId: categoryId);
      return items
          .where((e) => e.id != excludedId)
          .take(3)
          .toList(growable: false);
    } catch (_) {
      return const <ArticleModel>[];
    }
  }

  Future<String?> _fetchArticleHtmlFallback(String url) async {
    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 20000),
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/html'},
        ),
      ).get<String>(url);

      final html = response.data ?? '';
      if (html.isEmpty) return null;
      if (_looksLikeBotProtectionPage(html)) return null;

      final content = _extractMainContent(html);
      if (content == null || content.trim().isEmpty) return null;

      var cleaned = content;
      cleaned = cleaned.replaceAll(
          RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false), '');
      cleaned = cleaned.replaceAll(
          RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false), '');
      cleaned = cleaned.replaceAll(
          RegExp(r'<aside[\s\S]*?<\/aside>', caseSensitive: false), '');
      return cleaned.trim();
    } catch (_) {
      return null;
    }
  }

  String? _extractMainContent(String html) {
    const classCandidates = <String>[
      'entry-content',
      'post-content',
      'single-post-content',
      'article-content',
      'content-inner',
      'post-inner',
      'the-content',
      'item-content',
      'single-content',
      'post-body',
      'article-body',
    ];

    for (final candidate in classCandidates) {
      final block = _extractBalancedDivByClass(html, candidate);
      if (block != null && _visibleTextLength(block) >= 40) return block;
    }

    final patterns = <RegExp>[
      RegExp(r'<article[^>]*>([\s\S]*?)<\/article>', caseSensitive: false),
      RegExp(r'<main[^>]*>([\s\S]*?)<\/main>', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      final found = match?.group(1);
      if (found != null && found.trim().isNotEmpty) return found;
    }

    final paragraphMatches =
        RegExp(r'<p[^>]*>[\s\S]*?<\/p>', caseSensitive: false)
            .allMatches(html)
            .map((m) => m.group(0) ?? '')
            .where((s) => _visibleTextLength(s) >= 10)
            .toList(growable: false);
    if (paragraphMatches.length >= 2) {
      final joined = paragraphMatches.join('\n');
      if (_visibleTextLength(joined) >= 60) return joined;
    }

    return null;
  }

  String? _extractBalancedDivByClass(String html, String className) {
    final openTagPattern = RegExp(
      '<div[^>]*class=["\'][^"\']*\\b$className\\b[^"\']*["\'][^>]*>',
      caseSensitive: false,
    );
    final openMatch = openTagPattern.firstMatch(html);
    if (openMatch == null) return null;

    final startTagStart = openMatch.start;
    final startTagEnd = openMatch.end;
    final tagPattern = RegExp(r'<div\b[^>]*>|<\/div>', caseSensitive: false);
    final segment = html.substring(startTagEnd);

    var depth = 1;
    var endOffset = -1;

    for (final m in tagPattern.allMatches(segment)) {
      final token = segment.substring(m.start, m.end).toLowerCase();
      if (token.startsWith('<div')) {
        depth++;
      } else {
        depth--;
      }
      if (depth == 0) {
        endOffset = m.end;
        break;
      }
    }

    if (endOffset <= 0) return null;
    return html.substring(startTagStart, startTagEnd + endOffset).trim();
  }

  Future<List<String>> _fetchAttachmentImageUrls(int articleId) async {
    if (articleId <= 0) return const <String>[];
    try {
      final response = await _dio.get('/media', queryParameters: {
        'parent': articleId,
        'per_page': 25,
        'orderby': 'date',
        'order': 'desc',
      });
      final rows = response.data as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map((item) => (item['source_url'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <String>[];
    }
  }

  List<String> _extractImageUrls(String html) {
    final cleanedHtml = _stripKnownAuthorBlocks(html);
    final out = <String>{};
    final tagMatches =
        RegExp(r'<img\b[^>]*>', caseSensitive: false).allMatches(cleanedHtml);

    for (final match in tagMatches) {
      final tag = match.group(0) ?? '';
      final srcMatch = RegExp(
        r'''src=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(tag);
      final rawUrl = srcMatch?.group(1) ?? '';
      final normalized = _normalizeUrl(rawUrl);
      if (normalized == null || normalized.trim().isEmpty) continue;
      if (_isAuthorAvatarImage(tag, normalized)) continue;
      out.add(normalized);
    }

    return out.toList(growable: false);
  }

  List<String> _extractVideoUrls(String html) {
    final urls = <String>{};

    void extractByPattern(RegExp pattern) {
      for (final match in pattern.allMatches(html)) {
        final url = (match.group(1) ?? '').trim();
        if (url.isNotEmpty) {
          urls.add(url);
        }
      }
    }

    extractByPattern(
      RegExp("<iframe[^>]+src=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("<source[^>]+src=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("<video[^>]+src=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("<embed[^>]+src=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("(?:data-src|data-url)=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("<a[^>]+href=[\"']([^\"']+)[\"']", caseSensitive: false),
    );
    extractByPattern(
      RegExp("\\[(?:video|embed)[^\\]]*?src=[\"']([^\"']+)[\"']",
          caseSensitive: false),
    );
    extractByPattern(
      RegExp('"src"\\s*:\\s*"([^"]+)"', caseSensitive: false),
    );

    for (final match
        in RegExp("(https?:\\/\\/[^\\s\"'<>\\(\\)]+)", caseSensitive: false)
            .allMatches(html)) {
      final url = (match.group(1) ?? '').trim();
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }

    final normalized = urls
        .map(_normalizeUrl)
        .whereType<String>()
        .where(_isLikelyVideoUrl)
        .toList(growable: false);

    return _dedupeVideoUrls(normalized);
  }

  List<String> _extractVideoUrlsFromApiPayload(Map<String, dynamic> data) {
    final urls = <String>[];

    void walk(dynamic value, {String keyPath = ''}) {
      if (value is Map) {
        for (final entry in value.entries) {
          final nextPath =
              keyPath.isEmpty ? entry.key.toString() : '$keyPath.${entry.key}';
          walk(entry.value, keyPath: nextPath);
        }
        return;
      }

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk(value[i], keyPath: '$keyPath[$i]');
        }
        return;
      }

      if (value is String) {
        final lowerKey = keyPath.toLowerCase();
        final likelyByKey = lowerKey.contains('video') ||
            lowerKey.contains('embed') ||
            lowerKey.contains('iframe') ||
            lowerKey.contains('media_url');

        if (likelyByKey || _isLikelyVideoUrl(value)) {
          urls.addAll(_extractVideoUrls(value));
          final normalized = _normalizeUrl(value);
          if (normalized != null && _isLikelyVideoUrl(normalized)) {
            urls.add(normalized);
          }
        }
      }
    }

    walk(data);
    return _dedupeVideoUrls(urls);
  }

  List<String> _extractImageUrlsFromApiPayload(Map<String, dynamic> data) {
    final urls = <String>[];

    void walk(dynamic value, {String keyPath = ''}) {
      if (value is Map) {
        for (final entry in value.entries) {
          final nextPath =
              keyPath.isEmpty ? entry.key.toString() : '$keyPath.${entry.key}';
          walk(entry.value, keyPath: nextPath);
        }
        return;
      }

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk(value[i], keyPath: '$keyPath[$i]');
        }
        return;
      }

      if (value is String) {
        final lowerKey = keyPath.toLowerCase();
        if (_isAuthorAvatarKeyPath(lowerKey)) return;
        final likelyByKey = lowerKey.contains('image') ||
            lowerKey.contains('gallery') ||
            lowerKey.contains('slider') ||
            lowerKey.contains('thumbnail') ||
            lowerKey.contains('source_url');
        final normalized = _normalizeUrl(value);
        if (normalized != null &&
            (likelyByKey || _isLikelyImageUrl(normalized))) {
          if (_isLikelyImageUrl(normalized) &&
              !_looksLikeAuthorAvatarUrl(normalized)) {
            urls.add(normalized);
          }
        }
      }
    }

    walk(data);
    return _dedupeUrls(urls);
  }

  List<String> _extractAuthorAvatarUrlsFromApiPayload(
      Map<String, dynamic> data) {
    final urls = <String>[];

    void walk(dynamic value, {String keyPath = ''}) {
      if (value is Map) {
        for (final entry in value.entries) {
          final nextPath =
              keyPath.isEmpty ? entry.key.toString() : '$keyPath.${entry.key}';
          walk(entry.value, keyPath: nextPath);
        }
        return;
      }

      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          walk(value[i], keyPath: '$keyPath[$i]');
        }
        return;
      }

      if (value is String) {
        final lowerKey = keyPath.toLowerCase();
        if (!lowerKey.contains('avatar') &&
            !lowerKey.contains('author') &&
            !_looksLikeAuthorAvatarUrl(value)) {
          return;
        }

        final normalized = _normalizeUrl(value);
        if (normalized == null || !_isLikelyImageUrl(normalized)) return;
        urls.add(normalized);
      }
    }

    walk(data);
    return _dedupeUrls(urls);
  }

  String _normalizeContentHtml(
    String html, {
    List<String> extractedVideoUrls = const <String>[],
  }) {
    if (html.trim().isEmpty) return html;

    var normalized = html;
    if (extractedVideoUrls.isNotEmpty) {
      normalized = _stripVideoBlocks(normalized);
    }
    return normalized.trim();
  }

  String _stripVideoBlocks(String html) {
    var out = html;

    out = out.replaceAll(
      RegExp(r'<video\b[\s\S]*?<\/video>', caseSensitive: false),
      '',
    );

    out = out.replaceAll(
      RegExp(r'<iframe\b[\s\S]*?<\/iframe>', caseSensitive: false),
      '',
    );

    out = out.replaceAll(
      RegExp(r'<source\b[^>]*>', caseSensitive: false),
      '',
    );

    out = out.replaceAll(
      RegExp(r'<embed\b[^>]*>', caseSensitive: false),
      '',
    );

    // If cleaning produced an almost-empty body, keep original HTML to avoid
    // hiding article content due malformed/unbalanced external markup.
    final plain = out.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    final originalPlain = html.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (plain.length < 40 ||
        (originalPlain.length > 120 && plain.length < 60)) {
      return html;
    }

    return out;
  }

  String? _normalizeUrl(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

    var out = input
        .replaceAll('&amp;', '&')
        .replaceAll('\\/', '/')
        .replaceAll('"', '')
        .trim();

    if (out.startsWith('//')) {
      out = 'https:$out';
    }

    if (!(out.startsWith('http://') || out.startsWith('https://'))) {
      return null;
    }

    return out;
  }

  bool _isLikelyVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('vimeo.com') ||
        lower.contains('dailymotion.com') ||
        lower.contains('jwplayer') ||
        lower.contains('.mp4') ||
        lower.contains('.m3u8') ||
        lower.contains('.webm') ||
        lower.contains('.mov');
  }

  bool _isLikelyImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  List<String> _dedupeVideoUrls(List<String> input) {
    final seen = <String>{};
    final out = <String>[];

    for (final raw in input) {
      final normalized = _normalizeUrl(raw) ?? raw.trim();
      if (normalized.isEmpty) continue;
      final key = _canonicalVideoKey(normalized);
      if (seen.add(key)) {
        out.add(normalized);
      }
    }

    return out;
  }

  String _canonicalVideoKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (id.isNotEmpty) return 'youtube:$id';
    }
    if (host.contains('youtube.com')) {
      final id = uri.queryParameters['v'] ??
          (uri.pathSegments.contains('embed') ? uri.pathSegments.last : null);
      if (id != null && id.isNotEmpty) return 'youtube:$id';
    }
    if (host.contains('vimeo.com')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (id.isNotEmpty) return 'vimeo:$id';
    }

    final lowerPath = uri.path.toLowerCase();
    if (lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.m3u8') ||
        lowerPath.endsWith('.webm') ||
        lowerPath.endsWith('.mov')) {
      return '${uri.scheme}://${uri.host}$lowerPath';
    }

    return url.toLowerCase();
  }

  List<String> _dedupeUrls(List<String> input) {
    final seen = <String>{};
    final out = <String>[];

    for (final raw in input) {
      final normalized = _normalizeUrl(raw) ?? raw.trim();
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) {
        out.add(normalized);
      }
    }

    return out;
  }

  List<String> _removeAuthorAvatarsFromGallery(
      List<String> gallery, List<String> authorAvatarUrls) {
    if (gallery.isEmpty || authorAvatarUrls.isEmpty) return gallery;

    final avatarKeys = authorAvatarUrls.map(_canonicalImageKey).toSet();
    return gallery
        .where((url) => !avatarKeys.contains(_canonicalImageKey(url)))
        .toList(growable: false);
  }

  String _stripKnownAuthorBlocks(String html) {
    var out = html;
    out = out.replaceAll(
      RegExp(
        r'''<(?:div|figure)[^>]*class=["'][^"']*(?:author|avatar|meta-author|post-author|author-box|writer|byline)[^"']*["'][^>]*>[\s\S]*?<\/(?:div|figure)>''',
        caseSensitive: false,
      ),
      '',
    );
    return out;
  }

  String _canonicalImageKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.toLowerCase();
    var path = uri.path.toLowerCase();
    path = path.replaceAll(RegExp(r'-\d+x\d+(?=\.[a-z0-9]+$)'), '');
    return '${uri.host}$path';
  }

  bool _isAuthorAvatarImage(String imgTag, String imageUrl) {
    final lowerTag = imgTag.toLowerCase();
    if (lowerTag.contains('author-avatar') ||
        lowerTag.contains('avatar') ||
        lowerTag.contains('meta-author') ||
        lowerTag.contains('user-avatar') ||
        lowerTag.contains('gravatar')) {
      return true;
    }
    return _looksLikeAuthorAvatarUrl(imageUrl);
  }

  bool _isAuthorAvatarKeyPath(String lowerKeyPath) {
    return lowerKeyPath.contains('author') ||
        lowerKeyPath.contains('avatar') ||
        lowerKeyPath.contains('user') ||
        lowerKeyPath.contains('profile');
  }

  bool _looksLikeAuthorAvatarUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('gravatar.com/avatar') ||
        lower.contains('/avatar/') ||
        lower.contains('avatar=') ||
        lower.contains('user-avatar') ||
        lower.contains('author-avatar') ||
        lower.contains('profile_photo');
  }

  int _visibleTextLength(String html) {
    final plain = html
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return plain.length;
  }

  bool _looksLikeBotProtectionPage(String html) {
    final lower = html.toLowerCase();
    return lower.contains('imunify360') ||
        lower.contains('one moment, please') ||
        lower.contains('request is being verified') ||
        lower.contains('bot-protection');
  }

  String _normalizeArabicText(String input) {
    return input
        .trim()
        .replaceAll('\u0640', '')
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
  }
}
