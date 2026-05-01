import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/article_model.dart';
import '../../../shared/models/author_model.dart';
import '../../../shared/services/service_providers.dart';

class RelatedParams {
  const RelatedParams({required this.categoryId, required this.articleId});

  final int categoryId;
  final int articleId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelatedParams &&
        other.categoryId == categoryId &&
        other.articleId == articleId;
  }

  @override
  int get hashCode => Object.hash(categoryId, articleId);
}

final articleDetailsProvider =
    FutureProvider.family<ArticleModel, int>((ref, articleId) async {
  final article =
      await ref.read(wordpressServiceProvider).fetchArticle(articleId);
  ref
      .read(backendServiceProvider)
      .trackArticleOpen(articleId: article.id, title: article.title);
  return article;
});

final authorProvider =
    FutureProvider.family<AuthorModel?, int>((ref, authorId) async {
  return ref.read(wordpressServiceProvider).fetchAuthor(authorId);
});

final relatedArticlesProvider =
    FutureProvider.family<List<ArticleModel>, RelatedParams>(
        (ref, params) async {
  return ref
      .read(wordpressServiceProvider)
      .relatedByCategory(params.categoryId, params.articleId);
});
