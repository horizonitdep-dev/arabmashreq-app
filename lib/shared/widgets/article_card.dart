import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../models/article_model.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.compact = false,
    this.showExcerpt = false,
  });

  final ArticleModel article;
  final VoidCallback onTap;
  final bool compact;
  final bool showExcerpt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageWidth = compact ? 98.0 : 124.0;
    final imageHeight = compact ? 88.0 : 108.0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: article.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl!,
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            _placeholder(context, imageWidth, imageHeight),
                      )
                    : _placeholder(context, imageWidth, imageHeight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                    if (showExcerpt && article.excerpt.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _stripHtml(article.excerpt),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaDot(
                          icon: Icons.schedule_rounded,
                          label: article.date != null
                              ? DateFormat('yyyy/MM/dd').format(article.date!)
                              : 'تاريخ غير متاح',
                        ),
                        if (article.viewsCount != null)
                          _MetaDot(
                            icon: Icons.visibility_outlined,
                            label: NumberFormat.decimalPattern('ar')
                                .format(article.viewsCount),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double width, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF262626) : const Color(0xFFF0ECE0),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.gold),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
