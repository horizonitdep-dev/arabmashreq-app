import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/article_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/article_card.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/breaking_ticker.dart';
import '../../../shared/widgets/loading_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../../breaking_news/presentation/breaking_news_screen.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../data/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int? _selectedCategoryId;
  Timer? _unreadRefreshTimer;
  Future<List<ArticleModel>>? _selectedCategoryPostsFuture;
  int? _selectedCategoryPostsFutureId;
  final ScrollController _homeScrollController = ScrollController();
  final GlobalKey _categoryFeedKey = GlobalKey();
  String _selectedCategoryName = 'آخر الأخبار';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.invalidate(unreadNotificationsCountProvider);
    });
    _unreadRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        ref.invalidate(unreadNotificationsCountProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(unreadNotificationsCountProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unreadRefreshTimer?.cancel();
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredPostsProvider);
    final latestAsync = ref.watch(latestPostsProvider);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final breakingAsync = ref.watch(breakingTickerProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        centerTitle: false,
        titleSpacing: 0,
        title: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const BrandLogo(width: 116, height: 52),
              const SizedBox(width: 2),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(8, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\u0627\u0644\u0645\u0634\u0631\u0642 \u0627\u0644\u0639\u0631\u0628\u064a',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 19,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 16,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            '\u062d\u064a\u062b \u0627\u0644\u0643\u0644\u0645\u0629 \u0645\u0633\u0624\u0648\u0644\u064a\u0629 \u0648\u0627\u0644\u0631\u0624\u064a\u0629 \u0645\u0633\u062a\u0642\u0628\u0644',
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xSmall),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.lightSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child:
                        const Icon(Icons.notifications_none_rounded, size: 22),
                  ),
                  PositionedDirectional(
                    top: -2,
                    start: -2,
                    child: unreadAsync.when(
                      data: (count) {
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
            child: IconButton(
              onPressed: () => showSearch(
                context: context,
                delegate: _NewsSearchDelegate(ref),
              ),
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.search_rounded, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredPostsProvider);
          ref.invalidate(latestPostsProvider);
          ref.invalidate(homeCategoriesProvider);
          ref.invalidate(breakingTickerProvider);
          _selectedCategoryPostsFuture = null;
          _selectedCategoryPostsFutureId = null;
        },
        child: ListView(
          controller: _homeScrollController,
          padding: AppSpacing.pagePadding,
          children: [
            const SectionHeader(title: 'العاجل الآن'),
            const SizedBox(height: 8),
            breakingAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceAlt
                          : AppColors.lightSurfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      'لا توجد أخبار عاجلة حالياً',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return BreakingTicker(
                  items: items,
                  compact: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BreakingNewsScreen(),
                      ),
                    );
                  },
                );
              },
              loading: () => Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
              ),
              error: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceAlt
                      : AppColors.lightSurfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Text(
                  'تعذر تحميل شريط العاجل',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            categoriesAsync.when(
              data: _buildCategories,
              loading: () => const SizedBox(height: 42),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            const _AdSection(placement: 'home_top'),
            const SizedBox(height: 16),
            const SectionHeader(title: 'مختارات مميزة'),
            const SizedBox(height: 8),
            featuredAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const AppStateView(
                    icon: Icons.article_outlined,
                    title: 'لا توجد أخبار مميزة',
                    message: 'سيتم عرض الأخبار المميزة هنا عند توفرها.',
                  );
                }
                return _FeaturedSlider(posts: posts);
              },
              loading: () => const LoadingList(itemHeight: 226, count: 1),
              error: (_, __) => const AppStateView(
                icon: Icons.error_outline,
                title: 'تعذر تحميل الأخبار المميزة',
                message: 'اسحب للأسفل لإعادة المحاولة.',
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: _selectedCategoryName),
            const SizedBox(height: 8),
            Container(
              key: _categoryFeedKey,
              child: _buildLatest(latestAsync),
            ),
            const SizedBox(height: 16),
            const _AdSection(placement: 'home_between_feed', compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(List<CategoryModel> categories) {
    final list = categories.take(14).toList();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = _selectedCategoryId == null;
            return _CategoryChip(
              label: 'الكل',
              selected: selected,
              onTap: () => _selectCategory(null),
            );
          }

          final item = list[index - 1];
          final selected = _selectedCategoryId == item.id;
          return _CategoryChip(
            label: item.name,
            selected: selected,
            onTap: () => _selectCategory(item),
          );
        },
      ),
    );
  }

  void _selectCategory(CategoryModel? category) {
    setState(() {
      if (category == null) {
        _selectedCategoryId = null;
        _selectedCategoryName = 'آخر الأخبار';
        _selectedCategoryPostsFuture = null;
        _selectedCategoryPostsFutureId = null;
        return;
      }

      _selectedCategoryId = category.id;
      _selectedCategoryName = category.name;
      _selectedCategoryPostsFutureId = category.id;
      _selectedCategoryPostsFuture =
          ref.read(wordpressServiceProvider).fetchLatest(
                categoryId: category.id,
                perPage: 5,
              );
    });
    if (category != null) {
      _scrollToCategoryFeed();
    }
  }

  void _scrollToCategoryFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _categoryFeedKey.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    });
  }

  Widget _buildLatest(AsyncValue<List<ArticleModel>> latestAsync) {
    if (_selectedCategoryId != null) {
      if (_selectedCategoryPostsFuture == null ||
          _selectedCategoryPostsFutureId != _selectedCategoryId) {
        _selectedCategoryPostsFutureId = _selectedCategoryId;
        _selectedCategoryPostsFuture =
            ref.read(wordpressServiceProvider).fetchLatest(
                  categoryId: _selectedCategoryId,
                  perPage: 5,
                );
      }

      return FutureBuilder<List<ArticleModel>>(
        future: _selectedCategoryPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingList(itemHeight: 112, count: 5);
          }
          if (snapshot.hasError) {
            return const AppStateView(
              icon: Icons.wifi_off_rounded,
              title: 'تعذر تحميل القسم',
              message: 'تحقق من الاتصال ثم حاول مرة أخرى.',
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const AppStateView(
              icon: Icons.feed_outlined,
              title: 'لا توجد مقالات',
              message: 'لا توجد مقالات حالياً في هذا القسم.',
            );
          }

          return Column(
            children: posts
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ArticleCard(
                      article: post,
                      showExcerpt: true,
                      onTap: () =>
                          context.push('/article/${post.id}', extra: post),
                    ),
                  ),
                )
                .toList(),
          );
        },
      );
    }

    return latestAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const AppStateView(
            icon: Icons.newspaper_outlined,
            title: 'لا توجد أخبار حالياً',
            message: 'سيظهر المحتوى فور توفره.',
          );
        }

        return Column(
          children: posts
              .map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ArticleCard(
                    article: post,
                    showExcerpt: true,
                    onTap: () =>
                        context.push('/article/${post.id}', extra: post),
                  ),
                ),
              )
              .toList(),
        );
      },
      loading: () => const LoadingList(itemHeight: 112, count: 6),
      error: (_, __) => const AppStateView(
        icon: Icons.wifi_off_rounded,
        title: 'تعذر تحميل الأخبار',
        message: 'تحقق من الاتصال وحاول مرة أخرى.',
      ),
    );
  }
}

class _FeaturedSlider extends StatefulWidget {
  const _FeaturedSlider({required this.posts});

  final List<ArticleModel> posts;

  @override
  State<_FeaturedSlider> createState() => _FeaturedSliderState();
}

class _FeaturedSliderState extends State<_FeaturedSlider> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.posts.length == 1) {
      return SizedBox(
        height: 230,
        child: _FeaturedCard(article: widget.posts.first),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.posts.length,
          itemBuilder: (context, index, _) {
            final post = widget.posts[index];
            return _FeaturedCard(article: post);
          },
          options: CarouselOptions(
            height: 230,
            autoPlay: true,
            enableInfiniteScroll: true,
            autoPlayInterval: const Duration(seconds: 5),
            viewportFraction: 1,
            onPageChanged: (index, _) => setState(() => currentIndex = index),
          ),
        ),
        if (widget.posts.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.posts.length, (index) {
              final active = index == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: active ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.gold : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.article});

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/article/${article.id}', extra: article),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (article.imageUrl != null)
              Image.network(article.imageUrl!, fit: BoxFit.cover)
            else
              Container(color: Colors.black12),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Color(0x25000000)],
                ),
              ),
            ),
            PositionedDirectional(
              top: 12,
              start: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xCC101010),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.gold.withOpacity(0.65)),
                ),
                child: const Text(
                  'مميز',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? theme.brightness == Brightness.dark
                  ? const Color(0xFF2B2518)
                  : AppColors.sand
              : theme.cardTheme.color,
          border: Border.all(
            color: selected ? AppColors.gold : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? theme.colorScheme.secondary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _AdSection extends ConsumerStatefulWidget {
  const _AdSection({required this.placement, this.compact = false});

  final String placement;
  final bool compact;

  @override
  ConsumerState<_AdSection> createState() => _AdSectionState();
}

class _AdSectionState extends ConsumerState<_AdSection> {
  late Future<List<AdModel>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = _loadAds();
  }

  @override
  void didUpdateWidget(covariant _AdSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _adsFuture = _loadAds();
    }
  }

  Future<List<AdModel>> _loadAds() {
    return ref.read(backendServiceProvider).fetchAds(widget.placement);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdModel>>(
      future: _adsFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return AdBannerCarousel(ads: snapshot.data!, compact: widget.compact);
      },
    );
  }
}

class _NewsSearchDelegate extends SearchDelegate {
  _NewsSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  String? get searchFieldLabel => 'ابحث في الأخبار';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.close)),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const AppStateView(
        icon: Icons.manage_search_rounded,
        title: 'ابحث في الأخبار',
        message: 'اكتب كلمة مفتاحية لعرض النتائج.',
      );
    }

    return FutureBuilder<List<ArticleModel>>(
      future: ref.read(wordpressServiceProvider).searchArticles(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LoadingList(itemHeight: 112, count: 6),
          );
        }
        if (snapshot.hasError) {
          return const AppStateView(
            icon: Icons.error_outline,
            title: 'تعذر تنفيذ البحث',
            message: 'حاول مرة أخرى بعد قليل.',
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const AppStateView(
            icon: Icons.search_off,
            title: 'لا توجد نتائج',
            message: 'جرّب كلمات مختلفة أو صياغة أقصر.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final article = items[i];
            return ArticleCard(
              article: article,
              onTap: () =>
                  context.push('/article/${article.id}', extra: article),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const AppStateView(
      icon: Icons.newspaper_rounded,
      title: 'المشرق العربي',
      message: 'اكتب كلمة للبحث في محتوى الأخبار.',
    );
  }
}
