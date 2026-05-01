import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/ad_model.dart';
import '../../../shared/models/breaking_news_model.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/ad_banner.dart';
import '../../../shared/widgets/loading_list.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import 'breaking_news_provider.dart';

class BreakingNewsScreen extends ConsumerWidget {
  const BreakingNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(breakingNewsPageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            '\u0627\u0644\u0623\u062e\u0628\u0627\u0631 \u0627\u0644\u0639\u0627\u062c\u0644\u0629'),
        actions: [
          IconButton(
            tooltip: '\u062a\u062d\u062f\u064a\u062b',
            onPressed: () => ref.invalidate(breakingNewsPageProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: async.when(
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(breakingNewsPageProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
              children: [
                _BreakingHeroHeader(count: items.length),
                const SizedBox(height: 12),
                FutureBuilder<List<AdModel>>(
                  future: ref
                      .read(backendServiceProvider)
                      .fetchAds('breaking_news_page'),
                  builder: (_, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const SizedBox.shrink();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return AdBannerCarousel(
                      ads: snapshot.data!,
                      compact: true,
                    );
                  },
                ),
                if (items.isNotEmpty) const SizedBox(height: 14),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: AppStateView(
                      icon: Icons.notifications_none_rounded,
                      title:
                          '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u062e\u0628\u0627\u0631 \u0639\u0627\u062c\u0644\u0629 \u0627\u0644\u0622\u0646',
                      message:
                          '\u0633\u064a\u062a\u0645 \u0639\u0631\u0636 \u0627\u0644\u0623\u062e\u0628\u0627\u0631 \u0627\u0644\u0639\u0627\u062c\u0644\u0629 \u0647\u0646\u0627 \u0641\u0648\u0631 \u0646\u0634\u0631\u0647\u0627.',
                    ),
                  )
                else ...[
                  const SectionHeader(
                    title:
                        '\u0622\u062e\u0631 \u0627\u0644\u062a\u062d\u062f\u064a\u062b\u0627\u062a \u0627\u0644\u0639\u0627\u062c\u0644\u0629',
                  ),
                  const SizedBox(height: 8),
                  ...items.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BreakingHeadlineCard(
                            item: entry.value,
                            index: entry.key,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
          children: const [
            _BreakingHeroHeader(count: null),
            SizedBox(height: 14),
            LoadingList(itemHeight: 94, count: 6),
          ],
        ),
        error: (_, __) => const AppStateView(
          icon: Icons.error_outline,
          title:
              '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0623\u062e\u0628\u0627\u0631 \u0627\u0644\u0639\u0627\u062c\u0644\u0629',
          message:
              '\u062a\u062d\u0642\u0642 \u0645\u0646 \u0627\u0644\u0627\u062a\u0635\u0627\u0644 \u0648\u062d\u0627\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
        ),
      ),
    );
  }
}

class _BreakingHeroHeader extends StatelessWidget {
  const _BreakingHeroHeader({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF5A1212), Color(0xFF8E1E1E)]
              : const [Color(0xFFC33535), Color(0xFFE55353)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withOpacity(isDark ? 0.34 : 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u063a\u0631\u0641\u0629 \u0627\u0644\u0623\u062e\u0628\u0627\u0631 \u0627\u0644\u0639\u0627\u062c\u0644\u0629',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '\u062a\u062d\u062f\u064a\u062b\u0627\u062a \u0641\u0648\u0631\u064a\u0629 \u0648\u0645\u0633\u062a\u0645\u0631\u0629 \u0645\u0646 \u0627\u0644\u0645\u0635\u062f\u0631',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count == null
                  ? '...'
                  : '\u0627\u0644\u0622\u0646 ${count.toString()}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakingHeadlineCard extends StatelessWidget {
  const _BreakingHeadlineCard({required this.item, required this.index});

  final BreakingNewsModel item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gold.withOpacity(isDark ? 0.35 : 0.32),
          ),
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF181818), Color(0xFF121212)]
                : const [Color(0xFFFFFEFC), Color(0xFFF9F6EF)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 104,
              margin: const EdgeInsetsDirectional.only(start: 0),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.yellow.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.yellow.withOpacity(0.55),
                            ),
                          ),
                          child: const Text(
                            '\u062c\u062f\u064a\u062f',
                            style: TextStyle(
                              color: AppColors.yellow,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '#${index + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 1.6,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
