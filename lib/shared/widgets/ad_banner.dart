import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../models/ad_model.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key, required this.ad, this.compact = false});

  final AdModel ad;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (ad.externalUrl == null || ad.externalUrl!.trim().isEmpty) return;
          final uri = Uri.tryParse(ad.externalUrl!);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'إعلان',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ad.image != null
                    ? CachedNetworkImage(
                        imageUrl: ad.image!,
                        height: compact ? 114 : 162,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(compact),
                      )
                    : _placeholder(compact),
              ),
              if ((ad.ctaText ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF2D2616)
                        : const Color(0xFFF8EDCB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ad.ctaText!,
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.yellow
                          : const Color(0xFF5A4718),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(bool compact) {
    return Container(
      height: compact ? 114 : 162,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.campaign_outlined),
    );
  }
}

class AdBannerCarousel extends StatefulWidget {
  const AdBannerCarousel({
    super.key,
    required this.ads,
    this.compact = false,
  });

  final List<AdModel> ads;
  final bool compact;

  @override
  State<AdBannerCarousel> createState() => _AdBannerCarouselState();
}

class _AdBannerCarouselState extends State<AdBannerCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    if (widget.ads.length == 1) {
      return AdBanner(ad: widget.ads.first, compact: widget.compact);
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.ads.length,
          itemBuilder: (context, index, _) {
            return AdBanner(ad: widget.ads[index], compact: widget.compact);
          },
          options: CarouselOptions(
            height: widget.compact ? 236 : 284,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 500),
            onPageChanged: (index, _) => setState(() => _currentIndex = index),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (index) {
            final active = index == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
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
    );
  }
}

class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'إعلان',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: compact ? 114 : 162,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
