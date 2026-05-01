import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../features/auth/data/auth_controller.dart';
import '../../../features/auth/presentation/auth_screen.dart';
import '../../../features/bookmarks/presentation/bookmarks_controller.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/comment_model.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/article_card.dart';
import '../../../shared/widgets/loading_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../data/article_providers.dart';

class ArticleDetailsScreen extends ConsumerWidget {
  const ArticleDetailsScreen(
      {super.key, required this.articleId, this.initialArticle});

  final int articleId;
  final ArticleModel? initialArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articleDetailsProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () {
              ref.read(bookmarksControllerProvider.notifier).toggle(articleId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث المحفوظات')),
              );
            },
          ),
        ],
      ),
      body: async.when(
        data: (article) => _ArticleView(article: article),
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: LoadingList(itemHeight: 130, count: 4),
        ),
        error: (_, __) => const AppStateView(
          icon: Icons.error_outline,
          title: 'تعذر تحميل المقال',
          message: 'تحقق من الاتصال ثم حاول مرة أخرى.',
        ),
      ),
    );
  }
}

class _ArticleView extends ConsumerStatefulWidget {
  const _ArticleView({required this.article});

  final ArticleModel article;

  @override
  ConsumerState<_ArticleView> createState() => _ArticleViewState();
}

class _ArticleViewState extends ConsumerState<_ArticleView> {
  static const MethodChannel _nativeShareChannel =
      MethodChannel('com.arabmashreq.mobile/share');
  late final Future<List<AdModel>> _inlineAdsFuture;
  late final Future<List<AdModel>> _bottomAdsFuture;
  late Future<List<CommentModel>> _commentsFuture;
  late Future<int> _likesCountFuture;
  late Future<bool> _likedByUserFuture;

  final TextEditingController _commentController = TextEditingController();
  bool _sendingComment = false;
  bool _togglingLike = false;

  @override
  void initState() {
    super.initState();
    final backend = ref.read(backendServiceProvider);
    _inlineAdsFuture = backend.fetchAds('article_inline');
    _bottomAdsFuture = backend.fetchAds('article_bottom');
    _commentsFuture = backend.fetchCommentsByArticle(widget.article.id);
    _likesCountFuture = backend.fetchArticleLikesCount(widget.article.id);
    _likedByUserFuture = backend.fetchArticleLikedByUser(widget.article.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reloadComments() {
    setState(() {
      _commentsFuture = ref
          .read(backendServiceProvider)
          .fetchCommentsByArticle(widget.article.id);
    });
  }

  void _reloadLikes() {
    setState(() {
      _likesCountFuture = ref
          .read(backendServiceProvider)
          .fetchArticleLikesCount(widget.article.id);
      _likedByUserFuture = ref
          .read(backendServiceProvider)
          .fetchArticleLikedByUser(widget.article.id);
    });
  }

  Future<bool> _ensureAuthenticated() async {
    final authState = ref.read(authControllerProvider);
    if (authState.isAuthenticated) return true;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    return ref.read(authControllerProvider).isAuthenticated;
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final ok = await _ensureAuthenticated();
    if (!ok) return;

    setState(() => _sendingComment = true);
    try {
      await ref.read(backendServiceProvider).createComment(
            articleId: widget.article.id,
            content: text,
          );
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إرسال التعليق بنجاح وهو قيد المراجعة.')),
      );
      _reloadComments();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _toggleLike(bool likedByUser) async {
    final ok = await _ensureAuthenticated();
    if (!ok || _togglingLike) return;

    setState(() => _togglingLike = true);
    try {
      if (likedByUser) {
        await ref.read(backendServiceProvider).unlikeArticle(widget.article.id);
      } else {
        await ref.read(backendServiceProvider).likeArticle(widget.article.id);
      }
      _reloadLikes();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _togglingLike = false);
    }
  }

  Future<void> _replyToComment(CommentModel parent) async {
    final ok = await _ensureAuthenticated();
    if (!ok) return;

    final text = await _promptTextDialog(
      title: 'الرد على التعليق',
      hint: 'اكتب ردك هنا',
      confirmLabel: 'إرسال الرد',
    );
    if (text == null || text.trim().isEmpty) return;

    try {
      await ref.read(backendServiceProvider).replyToComment(
            articleId: widget.article.id,
            parentId: parent.id,
            content: text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرد بنجاح وهو قيد المراجعة.')),
      );
      _reloadComments();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reportComment(CommentModel comment) async {
    final ok = await _ensureAuthenticated();
    if (!ok) return;

    final reason = await _promptTextDialog(
      title: 'الإبلاغ عن تعليق',
      hint: 'سبب الإبلاغ',
      confirmLabel: 'إرسال الإبلاغ',
    );
    if (reason == null || reason.trim().isEmpty) return;

    try {
      await ref.read(backendServiceProvider).reportComment(
            commentId: comment.id,
            reason: reason.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الإبلاغ بنجاح.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التعليق'),
        content: const Text('هل تريد حذف هذا التعليق؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(backendServiceProvider).deleteComment(comment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التعليق.')),
      );
      _reloadComments();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _shareArticle(ArticleModel article) async {
    final title = article.title.trim();
    final link = article.link.trim();
    final text = <String>[title, link]
        .where((part) => part.isNotEmpty)
        .join('\n')
        .trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '\u0644\u0627 \u064a\u0648\u062c\u062f \u0645\u062d\u062a\u0648\u0649 \u0635\u0627\u0644\u062d \u0644\u0644\u0645\u0634\u0627\u0631\u0643\u0629.')),
      );
      return;
    }

    try {
      await Share.share(text);
    } catch (_) {
      try {
        await _nativeShareChannel.invokeMethod('shareText', <String, dynamic>{
          'text': text,
          if (title.isNotEmpty) 'subject': title,
        });
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  '\u062a\u0639\u0630\u0631 \u0641\u062a\u062d \u0646\u0627\u0641\u0630\u0629 \u0627\u0644\u0645\u0634\u0627\u0631\u0643\u0629 \u062d\u0627\u0644\u064a\u0627\u064b.')),
        );
      }
    }
  }

  Future<String?> _promptTextDialog({
    required String title,
    required String hint,
    required String confirmLabel,
  }) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.user?.id ?? 0;
    final authorAsync = ref.watch(authorProvider(article.authorId));
    final relatedAsync = ref.watch(
      relatedArticlesProvider(
        RelatedParams(
          categoryId:
              article.categoryIds.isEmpty ? 0 : article.categoryIds.first,
          articleId: article.id,
        ),
      ),
    );

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    final allImages = _dedupeImageUrls(<String>[
      if ((article.imageUrl ?? '').trim().isNotEmpty) article.imageUrl!,
      ...article.galleryImageUrls.where((url) => url.trim().isNotEmpty),
    ]);
    final videoUrls = article.videoEmbedUrls
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    final articleBodyHtml = _trimLeadingEmptyBlocks(
      _normalizeMetaLineBreaks(
        _removeNonContentBlocks(
          _removeVideoFromBody(article.contentHtml),
        ),
      ),
    );
    final articleBodyWithoutToc = _removeTocBlocks(articleBodyHtml);
    final hasVisibleArticleHtml =
        _visibleTextLength(articleBodyWithoutToc) > 40;
    final fallbackPlainText = _extractPlainText(
      article.contentHtml.isNotEmpty ? article.contentHtml : article.excerpt,
    );
    final viewsCount = article.viewsCount;
    final hasViewsCount = viewsCount != null;
    final viewsCountValue = viewsCount ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
      children: [
        if (allImages.isNotEmpty) _ArticleImageGallery(imageUrls: allImages),
        if (videoUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader(title: 'الفيديو'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: videoUrls
                    .map(
                      (url) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InlineVideoPlayer(url: url),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          article.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        authorAsync.when(
          data: (author) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: author?.avatarUrl != null
                          ? NetworkImage(author!.avatarUrl!)
                          : null,
                      child: author?.avatarUrl == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        author?.name ?? 'كاتب غير معروف',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                if (article.date != null || hasViewsCount) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (article.date != null)
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          label: DateFormat('yyyy/MM/dd')
                              .format(article.date!.toLocal()),
                        ),
                      if (hasViewsCount)
                        _MetaPill(
                          icon: Icons.visibility_outlined,
                          label: '${_formatViewsCount(viewsCountValue)} مشاهدة',
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                FutureBuilder<int>(
                  future: _likesCountFuture,
                  builder: (context, countSnap) {
                    final count = countSnap.data ?? 0;
                    return Expanded(
                      child: FutureBuilder<bool>(
                        future: _likedByUserFuture,
                        builder: (context, likedSnap) {
                          final liked = likedSnap.data ?? false;
                          return OutlinedButton.icon(
                            onPressed:
                                _togglingLike ? null : () => _toggleLike(liked),
                            icon: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: liked ? Colors.red : null,
                            ),
                            label: Text('إعجاب ($count)'),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareArticle(article),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('المشاركة'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'اقرأ في هذا المقال'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: hasVisibleArticleHtml
                ? Html(
                    data: articleBodyHtml,
                    style: {
                      'body': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        lineHeight: const LineHeight(2.05),
                        fontSize: const FontSize(18),
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      'p': Style(
                        margin: const EdgeInsets.only(top: 0, bottom: 16),
                        color: textColor,
                      ),
                      'div': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        color: textColor,
                      ),
                      'ul': Style(
                        margin: const EdgeInsets.only(top: 0, bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        color: textColor,
                        lineHeight: const LineHeight(1.9),
                      ),
                      'ol': Style(
                        margin: const EdgeInsets.only(top: 0, bottom: 12),
                        padding: const EdgeInsets.only(right: 20),
                        color: textColor,
                        lineHeight: const LineHeight(1.9),
                      ),
                      'h2': Style(
                        fontSize: const FontSize(24),
                        fontWeight: FontWeight.w800,
                        margin: const EdgeInsets.only(top: 0, bottom: 10),
                        color: textColor,
                      ),
                      'h3': Style(
                        fontSize: const FontSize(21),
                        fontWeight: FontWeight.w700,
                        margin: const EdgeInsets.only(top: 0, bottom: 8),
                        color: textColor,
                      ),
                      'a': Style(
                          color: AppColors.gold,
                          textDecoration: TextDecoration.none),
                      'img': Style(
                        display: Display.NONE,
                        margin: EdgeInsets.zero,
                      ),
                      'figure': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                      ),
                      '.ez-toc-container': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                      ),
                      '.ez-toc-title-container': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                      ),
                      '.ez-toc-title': Style(display: Display.NONE),
                      '.ez-toc-list': Style(
                        margin: const EdgeInsets.only(top: 0, bottom: 12),
                        padding: const EdgeInsets.only(right: 18),
                      ),
                      '.wp-block-image': Style(display: Display.NONE),
                      '.wp-block-gallery': Style(display: Display.NONE),
                      '.gallery': Style(display: Display.NONE),
                      '.slider-container': Style(display: Display.NONE),
                      '.post-bottom-meta': Style(
                        display: Display.BLOCK,
                        margin: const EdgeInsets.only(top: 14, bottom: 10),
                        padding: EdgeInsets.zero,
                      ),
                      '.post-bottom-meta-title': Style(
                        display: Display.BLOCK,
                        margin: const EdgeInsets.only(bottom: 6),
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      '.tagcloud': Style(
                        display: Display.BLOCK,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        color: textColor,
                      ),
                      '.meta-author-wrapper': Style(
                        display: Display.BLOCK,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: textColor,
                      ),
                      'blockquote': Style(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        padding: const EdgeInsets.all(10),
                        border: const Border(
                          right: BorderSide(color: AppColors.gold, width: 3),
                        ),
                        backgroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF191919)
                            : const Color(0xFFF8F6EE),
                        color: textColor,
                      ),
                      'li': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        lineHeight: const LineHeight(1.9),
                        color: textColor,
                      ),
                      '.widget-title': Style(display: Display.NONE),
                      '.the-global-title': Style(display: Display.NONE),
                      '.the-subtitle': Style(display: Display.NONE),
                      '#story-highlights': Style(
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                      ),
                    },
                    onLinkTap: (url, _, __, ___) async {
                      if (url == null) return;
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  )
                : (article.link.trim().isNotEmpty)
                    ? _ArticleWebContentInline(url: article.link)
                    : fallbackPlainText.isNotEmpty
                        ? Text(
                            fallbackPlainText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.95,
                              fontSize: 17,
                              color: textColor,
                            ),
                          )
                        : _NoContentFallback(article: article),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AdModel>>(
          future: _inlineAdsFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            return AdBannerCarousel(ads: snapshot.data!);
          },
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'التعليقات'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                if (!authState.isAuthenticated)
                  Row(
                    children: [
                      const Expanded(child: Text('سجل الدخول لإضافة تعليق.')),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AuthScreen())),
                        child: const Text('تسجيل الدخول'),
                      ),
                    ],
                  )
                else ...[
                  TextField(
                    controller: _commentController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'اكتب تعليقك هنا',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _sendingComment ? null : _submitComment,
                      icon: _sendingComment
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_outlined),
                      label: const Text('إرسال التعليق'),
                    ),
                  ),
                ],
                const Divider(height: 24),
                FutureBuilder<List<CommentModel>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingList(itemHeight: 90, count: 3);
                    }
                    if (snapshot.hasError) {
                      return const AppStateView(
                        icon: Icons.error_outline,
                        title: 'تعذر تحميل التعليقات',
                        message: 'حاول مرة أخرى لاحقاً.',
                      );
                    }

                    final comments = snapshot.data ?? const <CommentModel>[];
                    final commentsCount = comments.fold<int>(
                      comments.length,
                      (total, item) => total + item.replies.length,
                    );

                    if (comments.isEmpty) {
                      return const AppStateView(
                        icon: Icons.chat_bubble_outline,
                        title: 'لا توجد تعليقات بعد',
                        message: 'كن أول من يعلق على هذا الخبر.',
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('عدد التعليقات: $commentsCount',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...comments.map(
                          (comment) => _CommentTile(
                            comment: comment,
                            currentUserId: currentUserId,
                            onReply: (item) => _replyToComment(item),
                            onDelete: (item) => _deleteComment(item),
                            onReport: (item) => _reportComment(item),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'أخبار ذات صلة'),
        const SizedBox(height: 8),
        relatedAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const AppStateView(
                icon: Icons.article_outlined,
                title: 'لا توجد مقالات ذات صلة',
                message: 'سيتم إظهارها عند توفرها.',
              );
            }

            return Column(
              children: items
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ArticleCard(
                        article: e,
                        onTap: () => context.push('/article/${e.id}', extra: e),
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
          loading: () => const LoadingList(itemHeight: 110, count: 3),
          error: (_, __) => const AppStateView(
            icon: Icons.hourglass_empty_rounded,
            title: 'تعذر تحميل الأخبار ذات الصلة',
            message: 'ستتم المحاولة تلقائياً لاحقاً.',
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<AdModel>>(
          future: _bottomAdsFuture,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            return AdBannerCarousel(ads: snapshot.data!, compact: true);
          },
        ),
      ],
    );
  }

  String _removeVideoFromBody(String html) {
    var out = html;
    out = out.replaceAll(
      RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(
        r'<style[^>]*>[\s\S]*?(?:slider-container|slider-item|slider-btn)[\s\S]*?<\/style>',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceAll(
        RegExp(r'<video\b[\s\S]*?<\/video>', caseSensitive: false), '');
    out = out.replaceAll(
        RegExp(r'<iframe\b[\s\S]*?<\/iframe>', caseSensitive: false), '');
    out = out.replaceAll(
        RegExp(r'<amp-iframe\b[\s\S]*?<\/amp-iframe>', caseSensitive: false),
        '');
    out = out.replaceAll(
        RegExp(r'<object\b[\s\S]*?<\/object>', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'<source\b[^>]*>', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'<embed\b[^>]*>', caseSensitive: false), '');
    out = out.replaceAll(
      RegExp(
          r'<script[^>]*>[\s\S]*?(?:changeSlide|currentSlide|slider-item)[\s\S]*?<\/script>',
          caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(
          "<a[^>]+href=[\"'][^\"']+\\.(?:mp4|m3u8|webm|mov)[^\"']*[\"'][\\s\\S]*?<\\/a>",
          caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'https?:\/\/[^\s<"]+\.(?:mp4|m3u8|webm|mov)\b',
          caseSensitive: false),
      '',
    );
    final plain = out.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    if (plain.length < 40) return html;
    return out;
  }

  String _trimLeadingEmptyBlocks(String html) {
    var out = html.trimLeft();
    out = out.replaceAll(
      RegExp(
        r'^(?:<(?:p|div|span|section|article|figure)[^>]*>\s*(?:&nbsp;|\s|<br\s*\/?>)*<\/(?:p|div|span|section|article|figure)>\s*)+',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceAll(
      RegExp(r'^(?:\s|&nbsp;|<br\s*\/?>)+', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(
        r'^(?:<(?:div|span|section|article|figure|p)[^>]*>\s*(?:&nbsp;|\s|<br\s*\/?>|<!--[\s\S]*?-->)*<\/(?:div|span|section|article|figure|p)>\s*)+',
        caseSensitive: false,
      ),
      '',
    );
    return out.trimLeft();
  }

  String _removeNonContentBlocks(String html) {
    var out = html;

    out = out.replaceAll(
      RegExp(
        r'''<div[^>]*class=["'][^"']*(?:widget-title|the-global-title|the-subtitle|post-bottom-meta|post-bottom-source|post-shortlink)[^"']*["'][^>]*>[\s\S]*?<\/div>''',
        caseSensitive: false,
      ),
      '',
    );

    out = out.replaceAll(
      RegExp(r'''<input[^>]*id=["']short-post-url["'][^>]*>''',
          caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'''<button[^>]*id=["']copy-post-url["'][\s\S]*?<\/button>''',
          caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'''<span[^>]*id=["']copy-post-url-msg["'][\s\S]*?<\/span>''',
          caseSensitive: false),
      '',
    );

    out = out.replaceAll(
      RegExp(
        r'^(?:<(?:figure|div)[^>]*(?:wp-block-image|wp-block-gallery|slider-container|wp-block-video|wp-block-embed)[^>]*>[\s\S]*?<\/(?:figure|div)>\s*)+',
        caseSensitive: false,
      ),
      '',
    );

    return out;
  }

  String _normalizeMetaLineBreaks(String html) {
    var out = html;

    out = out.replaceAll(
      RegExp(
        r'(الكاتب\s*[:：]?\s*[^<\n\r]{1,120})\s+(المصدر\s*[:：]?)',
        caseSensitive: false,
      ),
      r'$1<br/>$2',
    );

    out = out.replaceAll(
      RegExp(
        r'(اسم\s+الكاتب\s*[:：]?\s*[^<\n\r]{1,120})\s+(المصدر\s*[:：]?)',
        caseSensitive: false,
      ),
      r'$1<br/>$2',
    );

    out = out.replaceAll(
      RegExp(
        r'(الكاتب)\s+(المصدر)',
        caseSensitive: false,
      ),
      r'$1<br/>$2',
    );

    return out;
  }

  int _visibleTextLength(String html) {
    final plain = _extractPlainText(html);
    return plain.length;
  }

  String _removeTocBlocks(String html) {
    return html.replaceAll(
      RegExp(
        "<div[^>]*class=[\"'][^\"']*ez-toc-container[^\"']*[\"'][\\s\\S]*?<\\/div>",
        caseSensitive: false,
      ),
      '',
    );
  }

  String _extractPlainText(String html) {
    var out = html;
    out = out.replaceAll(
      RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(r'<br\s*\/?>', caseSensitive: false),
      '\n',
    );
    out = out.replaceAll(
      RegExp(r'<\/(p|h1|h2|h3|h4|h5|h6|li|div|section|article|blockquote)>',
          caseSensitive: false),
      '\n',
    );
    out = out.replaceAll(RegExp(r'<[^>]+>'), ' ');
    out = out
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'");
    out = out.replaceAll(RegExp(r'[ \t]+'), ' ');
    out = out.replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
    return out.trim();
  }

  String _formatViewsCount(int views) {
    return NumberFormat.decimalPattern('ar').format(views);
  }

  List<String> _dedupeImageUrls(List<String> input) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in input) {
      final url = raw.trim();
      if (url.isEmpty) continue;
      final key = _canonicalImageKey(url);
      if (seen.add(key)) {
        out.add(url);
      }
    }
    return out;
  }

  String _canonicalImageKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.toLowerCase();
    var path = uri.path.toLowerCase();
    path = path.replaceAll(RegExp(r'-\d+x\d+(?=\.[a-z0-9]+$)'), '');
    return '${uri.host}$path';
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.035);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleImageGallery extends StatefulWidget {
  const _ArticleImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ArticleImageGallery> createState() => _ArticleImageGalleryState();
}

class _ArticleImageGalleryState extends State<_ArticleImageGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 244,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final imageUrl = widget.imageUrls[index];
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.gold : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url});

  final String url;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  Timer? _inlineControlsTimer;
  bool _showInlineControls = true;
  bool _isInlineScrubbing = false;
  double _inlineScrubValueMs = 0;

  @override
  void initState() {
    super.initState();
    if (_isDirectVideo(widget.url)) {
      _controller = VideoPlayerController.network(widget.url);
      _controller!.setLooping(false);
      _initFuture = _controller!.initialize();
    }
  }

  @override
  void dispose() {
    _inlineControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final embedUrl = _toEmbedUrl(widget.url);

    if (_controller != null) {
      return FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 210,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return _InlineWebVideo(url: embedUrl ?? widget.url);
          }

          final controller = _controller!;
          return ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final duration = value.duration;
              final position =
                  value.position > duration ? duration : value.position;
              final durationMs = duration.inMilliseconds.toDouble();
              final sliderMax = durationMs > 0 ? durationMs : 1.0;
              final positionMs =
                  position.inMilliseconds.toDouble().clamp(0.0, sliderMax);
              final sliderValue = _isInlineScrubbing
                  ? _inlineScrubValueMs.clamp(0.0, sliderMax)
                  : positionMs;
              final controlsVisible = _showInlineControls || !value.isPlaying;

              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: value.aspectRatio > 0
                            ? value.aspectRatio
                            : (16 / 9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller),
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _toggleInlineControls,
                                child: const SizedBox.expand(),
                              ),
                            ),
                            if (controlsVisible)
                              CircleAvatar(
                                radius: 27,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  onPressed: () =>
                                      _toggleInlinePlayPause(controller),
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (controlsVisible)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Fullscreen',
                                    onPressed: () => _openFullscreen(
                                      startAt: position,
                                      resumeInlineAfterClose: value.isPlaying,
                                    ),
                                    icon: const Icon(Icons.fullscreen,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbColor: AppColors.gold,
                                activeTrackColor: AppColors.gold,
                                inactiveTrackColor: Colors.grey.shade700,
                              ),
                              child: Slider(
                                value: sliderValue,
                                min: 0,
                                max: sliderMax,
                                onChangeStart: durationMs <= 0
                                    ? null
                                    : (v) {
                                        _cancelInlineControlsTimer();
                                        setState(() {
                                          _isInlineScrubbing = true;
                                          _inlineScrubValueMs = v;
                                          _showInlineControls = true;
                                        });
                                      },
                                onChanged: durationMs <= 0
                                    ? null
                                    : (v) {
                                        setState(() => _inlineScrubValueMs = v);
                                      },
                                onChangeEnd: durationMs <= 0
                                    ? null
                                    : (v) async {
                                        setState(() {
                                          _isInlineScrubbing = false;
                                          _inlineScrubValueMs = v;
                                        });
                                        await controller.seekTo(
                                          Duration(milliseconds: v.round()),
                                        );
                                        _scheduleInlineControlsHide();
                                      },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      _toggleInlinePlayPause(controller),
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_fill,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Fullscreen',
                                  onPressed: () => _openFullscreen(
                                    startAt: position,
                                    resumeInlineAfterClose: value.isPlaying,
                                  ),
                                  icon: const Icon(Icons.fullscreen,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    if (embedUrl == null) return const SizedBox.shrink();
    return _InlineWebVideo(url: embedUrl);
  }

  bool _isDirectVideo(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.m3u8') ||
        lower.contains('.webm') ||
        lower.contains('.mov');
  }

  String? _toEmbedUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    String youtubeEmbed(String id) =>
        'https://www.youtube.com/embed/$id?playsinline=1&controls=1&fs=1&rel=0';

    if (host.contains('youtu.be')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      if (id.isNotEmpty) return youtubeEmbed(id);
    }

    if (host.contains('youtube.com')) {
      if (uri.path.contains('/embed/')) {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (id.isNotEmpty) return youtubeEmbed(id);
        return url;
      }
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) {
        return youtubeEmbed(id);
      }
    }

    if (host.contains('vimeo.com')) {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (id.isNotEmpty) {
        return 'https://player.vimeo.com/video/$id?title=0&byline=0';
      }
    }

    return url.startsWith('http://') || url.startsWith('https://') ? url : null;
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleInlinePlayPause(VideoPlayerController controller) async {
    if (controller.value.isPlaying) {
      await controller.pause();
      _cancelInlineControlsTimer();
      if (!mounted) return;
      setState(() => _showInlineControls = true);
      return;
    }

    await controller.play();
    if (!mounted) return;
    setState(() => _showInlineControls = true);
    _scheduleInlineControlsHide();
  }

  void _toggleInlineControls() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      if (!_showInlineControls) {
        _showInlineControls = true;
      } else if (controller.value.isPlaying) {
        _showInlineControls = false;
      }
    });

    if (_showInlineControls) {
      _scheduleInlineControlsHide();
    } else {
      _cancelInlineControlsTimer();
    }
  }

  void _scheduleInlineControlsHide() {
    _cancelInlineControlsTimer();
    final controller = _controller;
    if (controller == null || !controller.value.isPlaying) return;
    _inlineControlsTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_isInlineScrubbing) return;
      setState(() => _showInlineControls = false);
    });
  }

  void _cancelInlineControlsTimer() {
    _inlineControlsTimer?.cancel();
    _inlineControlsTimer = null;
  }

  Future<void> _openFullscreen({
    required Duration startAt,
    required bool resumeInlineAfterClose,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    final wasPlayingInline = controller.value.isPlaying;
    if (wasPlayingInline) {
      await controller.pause();
    }
    if (!mounted) return;

    final result = await Navigator.of(context).push<_FullscreenPlaybackResult>(
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPlayer(
          url: widget.url,
          startAt: startAt,
          autoPlay: resumeInlineAfterClose,
        ),
      ),
    );

    if (!mounted) return;
    final effectiveResult = result ??
        _FullscreenPlaybackResult(position: startAt, resumePlayback: false);
    await controller.seekTo(effectiveResult.position);
    if (effectiveResult.resumePlayback && controller.value.isInitialized) {
      await controller.play();
      if (mounted) {
        setState(() => _showInlineControls = true);
      }
      _scheduleInlineControlsHide();
    } else {
      _cancelInlineControlsTimer();
      if (mounted) {
        setState(() => _showInlineControls = true);
      }
    }
  }
}

class _FullscreenPlaybackResult {
  const _FullscreenPlaybackResult({
    required this.position,
    required this.resumePlayback,
  });

  final Duration position;
  final bool resumePlayback;
}

class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({
    required this.url,
    required this.startAt,
    required this.autoPlay,
  });

  final String url;
  final Duration startAt;
  final bool autoPlay;

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initFuture;
  bool _isFullscreenScrubbing = false;
  double _fullscreenScrubValueMs = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url);
    _controller.setLooping(false);
    _initFuture = _initAndPrepare();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _initAndPrepare() async {
    await _controller.initialize();
    final safeSeek = widget.startAt <= _controller.value.duration
        ? widget.startAt
        : Duration.zero;
    if (safeSeek > Duration.zero) {
      await _controller.seekTo(safeSeek);
    }
    if (widget.autoPlay) {
      await _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _close() async {
    final value = _controller.value;
    Navigator.of(context).pop(
      _FullscreenPlaybackResult(
        position: value.position,
        resumePlayback: value.isPlaying,
      ),
    );
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: _close,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text(
                  'تعذر تحميل الفيديو - إغلاق',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          return ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final duration = value.duration;
              final position =
                  value.position > duration ? duration : value.position;
              final durationMs = duration.inMilliseconds.toDouble();
              final sliderMax = durationMs > 0 ? durationMs : 1.0;
              final positionMs =
                  position.inMilliseconds.toDouble().clamp(0.0, sliderMax);
              final sliderValue = _isFullscreenScrubbing
                  ? _fullscreenScrubValueMs.clamp(0.0, sliderMax)
                  : positionMs;

              return Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio:
                          value.aspectRatio > 0 ? value.aspectRatio : (16 / 9),
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  Positioned(
                    top: 24,
                    left: 20,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.fullscreen_exit,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xAA000000), Color(0x22000000)],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbColor: AppColors.gold,
                              activeTrackColor: AppColors.gold,
                              inactiveTrackColor: Colors.grey.shade700,
                            ),
                            child: Slider(
                              value: sliderValue,
                              min: 0,
                              max: sliderMax,
                              onChangeStart: durationMs <= 0
                                  ? null
                                  : (v) {
                                      setState(() {
                                        _isFullscreenScrubbing = true;
                                        _fullscreenScrubValueMs = v;
                                      });
                                    },
                              onChanged: durationMs <= 0
                                  ? null
                                  : (v) {
                                      setState(
                                          () => _fullscreenScrubValueMs = v);
                                    },
                              onChangeEnd: durationMs <= 0
                                  ? null
                                  : (v) async {
                                      setState(() {
                                        _isFullscreenScrubbing = false;
                                        _fullscreenScrubValueMs = v;
                                      });
                                      await _controller.seekTo(
                                        Duration(milliseconds: v.round()),
                                      );
                                    },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  if (value.isPlaying) {
                                    await _controller.pause();
                                  } else {
                                    await _controller.play();
                                  }
                                },
                                icon: Icon(
                                  value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                onPressed: _close,
                                icon: const Icon(Icons.fullscreen_exit,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InlineWebVideo extends StatelessWidget {
  const _InlineWebVideo({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}

class _ArticleWebContentInline extends StatelessWidget {
  const _ArticleWebContentInline({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 620,
        child: WebView(
          initialUrl: url,
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final CommentModel comment;
  final int currentUserId;
  final Future<void> Function(CommentModel comment) onReply;
  final Future<void> Function(CommentModel comment) onDelete;
  final Future<void> Function(CommentModel comment) onReport;

  @override
  Widget build(BuildContext context) {
    Widget buildBubble(CommentModel item, {bool isReply = false}) {
      final canDeleteItem = currentUserId > 0 && item.userId == currentUserId;
      return Container(
        margin: EdgeInsets.only(bottom: 8, right: isReply ? 18 : 0),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isReply
              ? Theme.of(context).dividerColor.withOpacity(0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: (item.userAvatarUrl ?? '').isNotEmpty
                      ? NetworkImage(item.userAvatarUrl!)
                      : null,
                  child: (item.userAvatarUrl ?? '').isEmpty
                      ? const Icon(Icons.person_outline, size: 14)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.userName,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text(
                  item.createdAt == null
                      ? ''
                      : DateFormat('yyyy/MM/dd HH:mm')
                          .format(item.createdAt!.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.content),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (!isReply)
                  TextButton.icon(
                    onPressed: () => onReply(item),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('\u0631\u062f'),
                  ),
                TextButton.icon(
                  onPressed: () => onReport(item),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('\u0625\u0628\u0644\u0627\u063a'),
                ),
                if (canDeleteItem)
                  TextButton.icon(
                    onPressed: () => onDelete(item),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('\u062d\u0630\u0641'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBubble(comment),
        ...comment.replies.map((reply) => buildBubble(reply, isReply: true)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NoContentFallback extends StatelessWidget {
  const _NoContentFallback({required this.article});

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('محتوى هذا المقال غير متوفر من واجهة الموقع حالياً.'),
        const SizedBox(height: 10),
        if (article.excerpt.trim().isNotEmpty)
          Html(
            data: article.excerpt,
            style: {
              'body': Style(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                color: textColor,
              ),
              'p': Style(color: textColor),
            },
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.tryParse(article.link);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('فتح من المصدر'),
        ),
      ],
    );
  }
}
