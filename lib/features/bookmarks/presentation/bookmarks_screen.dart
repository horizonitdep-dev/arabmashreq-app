import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/article_model.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/widgets/article_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import 'bookmarks_controller.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(bookmarksControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المحفوظات')),
      body: ids.isEmpty
          ? const AppStateView(
              icon: Icons.bookmark_border_rounded,
              title: 'لا توجد مقالات محفوظة',
              message: 'احفظ أي مقال ليظهر هنا لاحقاً.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final id = ids[index];
                return FutureBuilder<ArticleModel>(
                  future: ref.read(wordpressServiceProvider).fetchArticle(id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _BookmarkLoadingCard();
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Card(
                        child: ListTile(
                          title: const Text('تعذر تحميل المقال المحفوظ'),
                          subtitle: Text('المعرف: $id'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref
                                .read(bookmarksControllerProvider.notifier)
                                .toggle(id),
                          ),
                        ),
                      );
                    }

                    final article = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (index == 0) ...[
                          const SectionHeader(title: 'مقالاتك المحفوظة'),
                          const SizedBox(height: 8),
                        ],
                        ArticleCard(
                          article: article,
                          showExcerpt: true,
                          onTap: () => context.push('/article/${article.id}',
                              extra: article),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => ref
                                .read(bookmarksControllerProvider.notifier)
                                .toggle(id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('إزالة من المحفوظات'),
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

class _BookmarkLoadingCard extends StatelessWidget {
  const _BookmarkLoadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isDark ? const Color(0xFF252525) : const Color(0xFFEAEAEA),
        ),
      ),
    );
  }
}
