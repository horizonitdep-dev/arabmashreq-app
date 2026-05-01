import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/ad_model.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/article_card.dart';
import '../../../shared/widgets/loading_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../../home/data/home_providers.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(homeCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      body: categories.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppStateView(
              icon: Icons.grid_view_rounded,
              title: 'لا توجد أقسام',
              message: 'سيتم عرض الأقسام هنا عند توفرها.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
            ),
            itemBuilder: (_, i) {
              final c = items[i];
              return _CategoryTile(
                category: c,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailsScreen(category: c),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: LoadingList(itemHeight: 84, count: 8),
        ),
        error: (_, __) => const AppStateView(
          icon: Icons.error_outline,
          title: 'تعذر تحميل الأقسام',
          message: 'تحقق من الاتصال وحاول مرة أخرى.',
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForCategory(category.name);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.18),
                child: Icon(
                  icon,
                  color: theme.colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String rawName) {
    final name = rawName.trim().toLowerCase();

    if (_hasAny(name, const ['رياض', 'كرة', 'sport'])) {
      return Icons.sports_soccer_rounded;
    }
    if (_hasAny(name, const ['اقتص', 'مال', 'اعمال', 'أعمال', 'business'])) {
      return Icons.trending_up_rounded;
    }
    if (_hasAny(name, const ['سياس', 'parliament', 'policy'])) {
      return Icons.account_balance_rounded;
    }
    if (_hasAny(name, const ['ثقاف', 'فن', 'culture', 'art'])) {
      return Icons.palette_rounded;
    }
    if (_hasAny(name, const ['اعلام', 'إعلام', 'تنمي', 'media'])) {
      return Icons.perm_media_rounded;
    }
    if (_hasAny(name, const ['سياح', 'تراث', 'tour', 'heritage'])) {
      return Icons.travel_explore_rounded;
    }
    if (_hasAny(
        name, const ['تقرير', 'تقارير', 'تحقيق', 'report', 'investig'])) {
      return Icons.fact_check_rounded;
    }
    if (_hasAny(
        name, const ['شخصيات', 'صناع', 'قرار', 'leaders', 'decision'])) {
      return Icons.groups_rounded;
    }
    if (_hasAny(name, const ['شعر', 'poetry', 'poem'])) {
      return Icons.auto_stories_rounded;
    }
    if (_hasAny(name, const ['تقن', 'تكنولوج', 'tech', 'digital'])) {
      return Icons.memory_rounded;
    }
    if (_hasAny(name, const ['صح', 'طب', 'health', 'medical'])) {
      return Icons.local_hospital_rounded;
    }
    if (_hasAny(name, const ['تعليم', 'مدرس', 'جامع', 'education'])) {
      return Icons.school_rounded;
    }
    if (_hasAny(name, const ['دول', 'عالم', 'world', 'international'])) {
      return Icons.public_rounded;
    }
    if (_hasAny(name, const ['دين', 'اسلام', 'إسلام', 'religion'])) {
      return Icons.menu_book_rounded;
    }
    if (_hasAny(name, const ['طقس', 'مناخ', 'weather'])) {
      return Icons.wb_sunny_rounded;
    }
    if (_hasAny(name, const ['رأي', 'تحليل', 'opinion'])) {
      return Icons.rate_review_rounded;
    }
    if (_hasAny(name, const ['عاجل', 'breaking'])) {
      return Icons.campaign_rounded;
    }
    if (_hasAny(name, const ['خاص', 'special'])) {
      return Icons.stars_rounded;
    }
    if (_hasAny(name, const ['مجتمع', 'منوع', 'lifestyle'])) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.folder_open_rounded;
  }

  bool _hasAny(String text, List<String> keys) {
    for (final key in keys) {
      if (text.contains(key.toLowerCase())) return true;
    }
    return false;
  }
}

class CategoryDetailsScreen extends ConsumerStatefulWidget {
  const CategoryDetailsScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  ConsumerState<CategoryDetailsScreen> createState() =>
      _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends ConsumerState<CategoryDetailsScreen> {
  final List<ArticleModel> _posts = <ArticleModel>[];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  late Future<List<AdModel>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = ref.read(backendServiceProvider).fetchAds('category_page');
    _loadPage(reset: true);
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _posts.clear();
      }
      _error = null;
    });

    try {
      final pageToLoad = _page;
      final items = await ref.read(wordpressServiceProvider).fetchLatest(
            categoryId: widget.category.id,
            page: pageToLoad,
            perPage: 10,
          );

      if (!mounted) return;
      setState(() {
        _posts.addAll(items);
        _hasMore = items.length == 10;
        if (_hasMore) _page += 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل المقالات.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'أخبار القسم'),
                const SizedBox(height: 10),
                FutureBuilder<List<AdModel>>(
                  future: _adsFuture,
                  builder: (_, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          AdBannerCarousel(ads: snapshot.data!, compact: true),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_posts.isEmpty && _isLoading)
          const SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: LoadingList(itemHeight: 112, count: 6),
            ),
          )
        else if (_posts.isEmpty && !_isLoading && _error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppStateView(
              icon: Icons.error_outline,
              title: 'تعذر تحميل المقالات',
              message: _error!,
              actionLabel: 'إعادة المحاولة',
              onAction: () => _loadPage(reset: true),
            ),
          )
        else if (_posts.isEmpty && !_isLoading && _error == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: AppStateView(
              icon: Icons.feed_outlined,
              title: 'لا توجد مقالات',
              message: 'لا توجد مقالات متاحة في هذا القسم الآن.',
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final article = _posts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ArticleCard(
                      article: article,
                      showExcerpt: true,
                      onTap: () => context.push('/article/${article.id}',
                          extra: article),
                    ),
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
              child: Column(
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_isLoading && _hasMore)
                    ElevatedButton(
                      onPressed: _loadPage,
                      child: const Text('تحميل المزيد'),
                    ),
                  if (!_isLoading && !_hasMore)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(child: Text('تم عرض جميع المقالات')),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: RefreshIndicator(
        onRefresh: () => _loadPage(reset: true),
        child: content,
      ),
    );
  }
}
