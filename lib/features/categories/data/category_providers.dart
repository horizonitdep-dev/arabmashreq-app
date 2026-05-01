import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/article_model.dart';
import '../../../shared/services/service_providers.dart';

class CategoryPostsParams {
  const CategoryPostsParams({required this.categoryId, required this.page});

  final int categoryId;
  final int page;
}

final categoryPostsProvider = FutureProvider.family<List<ArticleModel>, CategoryPostsParams>((ref, params) async {
  return ref
      .read(wordpressServiceProvider)
      .fetchLatest(page: params.page, perPage: 10, categoryId: params.categoryId);
});
