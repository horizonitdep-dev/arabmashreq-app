import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/article_model.dart';
import '../../../shared/models/breaking_news_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/service_providers.dart';

final homeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.read(wordpressServiceProvider).fetchCategories();
});

final latestPostsProvider =
    FutureProvider.autoDispose<List<ArticleModel>>((ref) async {
  return ref.read(wordpressServiceProvider).fetchLatest(page: 1, perPage: 20);
});

final featuredPostsProvider =
    FutureProvider.autoDispose<List<ArticleModel>>((ref) async {
  final wordpress = ref.read(wordpressServiceProvider);
  final specialCategoryId = await wordpress.findCategoryIdByName('خاص');

  if (specialCategoryId != null) {
    return wordpress.fetchLatest(
      page: 1,
      perPage: 10,
      categoryId: specialCategoryId,
    );
  }

  return wordpress.fetchLatest(page: 1, perPage: 10);
});

final breakingTickerProvider =
    FutureProvider.autoDispose<List<BreakingNewsModel>>((ref) async {
  return ref.read(backendServiceProvider).fetchBreakingNews();
});
