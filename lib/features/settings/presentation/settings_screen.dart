import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/models/notification_preferences_model.dart';
import '../../../shared/services/service_providers.dart';
import '../../../shared/utils/share_helper.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../home/data/home_providers.dart';
import '../../notifications/presentation/notifications_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/settings_controller.dart';

final appSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(backendServiceProvider).fetchAppSettings();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final appSettingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ø§Ù„Ù…Ø²ÙŠØ¯')),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          _AccountCard(authState: authState),
          const SizedBox(height: AppSpacing.small),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ø§Ù„Ù…Ø¸Ù‡Ø± ÙˆØ§Ù„Ù‚Ø±Ø§Ø¡Ø©',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ø§Ù„ÙˆØ¶Ø¹ Ø§Ù„Ø¯Ø§ÙƒÙ†'),
                    subtitle: const Text(
                        'ØªÙØ¹ÙŠÙ„ Ø§Ù„Ù…Ø¸Ù‡Ø± Ø§Ù„Ø¯Ø§ÙƒÙ† Ù„Ù‚Ø±Ø§Ø¡Ø© Ù…Ø±ÙŠØ­Ø© Ù„ÙŠÙ„Ù‹Ø§.'),
                    value: state.isDarkMode,
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .toggleDarkMode(v),
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text('Ø­Ø¬Ù… Ø§Ù„Ø®Ø·',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xSmall / 2),
                  Slider(
                    value: state.fontScale,
                    min: 0.9,
                    max: 1.3,
                    divisions: 4,
                    label: state.fontScale.toStringAsFixed(1),
                    onChanged: (v) => ref
                        .read(settingsControllerProvider.notifier)
                        .updateFontScale(v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Ø£ØµØºØ±'),
                      Text('Ø£ÙƒØ¨Ø±'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          _NotificationPreferencesSection(authState: authState),
          const SizedBox(height: AppSpacing.small),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.gold),
              title: const Text('ØµÙ†Ø¯ÙˆÙ‚ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª'),
              subtitle: const Text(
                  'Ø¹Ø±Ø¶ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ù…Ø­ÙÙˆØ¸Ø© ÙˆÙØªØ­ Ø§Ù„Ù…Ø­ØªÙˆÙ‰ Ø§Ù„Ù…Ø±ØªØ¨Ø· Ø¨Ù‡Ø§.'),
              trailing: unreadAsync.when(
                data: (count) {
                  if (count <= 0) {
                    return const Icon(Icons.chevron_left_rounded);
                  }
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(Icons.chevron_left_rounded),
              ),
              onTap: () => context.push('/notifications'),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Card(
            child: Column(
              children: const [
                _StaticPageTile(
                  title: 'Ù…Ù† Ù†Ø­Ù†',
                  icon: Icons.info_outline_rounded,
                  settingKey: 'about_us',
                ),
                Divider(height: 1),
                _StaticPageTile(
                  title: 'Ø§Ù„ÙØ±ÙŠÙ‚',
                  icon: Icons.people_outline,
                  settingKey: 'team',
                ),
                Divider(height: 1),
                _StaticPageTile(
                  title: 'Ø³ÙŠØ§Ø³Ø© Ø§Ù„Ø®ØµÙˆØµÙŠØ©',
                  icon: Icons.privacy_tip_outlined,
                  settingKey: 'privacy_policy',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          _SupportAndSocialCard(appSettingsAsync: appSettingsAsync),
          const SizedBox(height: AppSpacing.small),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.share_outlined, color: AppColors.gold),
                  title: const Text('Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„ØªØ·Ø¨ÙŠÙ‚'),
                  subtitle: const Text(
                      'Ø´Ø§Ø±Ùƒ Ø§Ù„ØªØ·Ø¨ÙŠÙ‚ Ù…Ø¹ Ø§Ù„Ø£ØµØ¯Ù‚Ø§Ø¡.'),
                  onTap: () => _shareApp(context, appSettingsAsync),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.verified_outlined, color: AppColors.gold),
                  title: Text('Ø§Ù„Ø¥ØµØ¯Ø§Ø±'),
                  subtitle: Text('1.0.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareApp(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> appSettingsAsync,
  ) async {
    final settings = appSettingsAsync.asData?.value;
    final storeLinks = _normalizeStoreLinks(settings?['app_store_links']);
    final text = _buildAppShareText(storeLinks);

    await ShareHelper.shareText(
      context,
      text: text,
      subject: AppConfig.appName,
    );
  }

  String _buildAppShareText(Map<String, String> storeLinks) {
    final lines = <String>[
      'تطبيق ${AppConfig.appName}',
    ];

    final ios = storeLinks['ios'];
    final android = storeLinks['android'];

    if (ios != null && ios.isNotEmpty) {
      lines.add('iOS: $ios');
    }
    if (android != null && android.isNotEmpty) {
      lines.add('Android: $android');
    }

    return lines.join('\n');
  }

  Map<String, String> _normalizeStoreLinks(dynamic raw) {
    if (raw == null) return const {};

    dynamic decoded = raw;
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return const {};
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        return const {};
      }
    }

    if (decoded is! Map) return const {};

    final links = <String, String>{};
    for (final key in const ['ios', 'android']) {
      final value = (decoded[key] ?? '').toString().trim();
      if (value.isEmpty) continue;
      final uri = _normalizeStoreUri(value);
      if (uri == null) continue;
      links[key] = uri.toString();
    }
    return links;
  }

  Uri? _normalizeStoreUri(String rawUrl) {
    var cleaned = rawUrl.trim();
    if (cleaned.isEmpty) return null;

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('//')) {
      cleaned = 'https:$cleaned';
    }

    Uri? uri = Uri.tryParse(cleaned);
    if (uri == null) return null;
    if (uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$cleaned');
    }
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    if (uri.host.trim().isEmpty) return null;
    return uri;
  }
}

class _SupportAndSocialCard extends StatelessWidget {
  const _SupportAndSocialCard({required this.appSettingsAsync});

  final AsyncValue<Map<String, dynamic>> appSettingsAsync;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gold.withOpacity(isDark ? 0.25 : 0.16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDark
                ? [
                    const Color(0xFF1B1B1B),
                    const Color(0xFF101010),
                  ]
                : [
                    AppColors.gold.withOpacity(0.14),
                    Colors.white.withOpacity(0.92),
                  ],
          ),
        ),
        child: appSettingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0628\u064a\u0627\u0646\u0627\u062a \u0627\u0644\u062a\u0648\u0627\u0635\u0644 \u062d\u0627\u0644\u064a\u064b\u0627.',
            ),
          ),
          data: (settings) {
            final supportPhone =
                (settings['support_phone'] ?? '').toString().trim();
            final supportPhoneNormalized = _normalizeSupportPhone(supportPhone);
            final supportEmail =
                (settings['support_email'] ?? '').toString().trim();
            final socialLinks = _normalizeSocialLinks(settings['social_links']);
            final hasAnyData = supportPhoneNormalized.isNotEmpty ||
                supportEmail.isNotEmpty ||
                socialLinks.isNotEmpty;

            if (!hasAnyData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '\u0644\u0627 \u062a\u0648\u062c\u062f \u0628\u064a\u0627\u0646\u0627\u062a \u062a\u0648\u0627\u0635\u0644 \u0645\u062a\u0648\u0641\u0631\u0629 \u0641\u064a \u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a.',
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.support_agent_rounded, color: AppColors.gold),
                      SizedBox(width: AppSpacing.xSmall),
                      Text(
                        '\u062a\u0648\u0627\u0635\u0644 \u0645\u0639\u0646\u0627',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (supportPhoneNormalized.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.small),
                    _ContactTile(
                      icon: Icons.phone_in_talk_rounded,
                      label:
                          '\u0647\u0627\u062a\u0641 \u0627\u0644\u062f\u0639\u0645',
                      value: supportPhoneNormalized,
                      forceLtr: true,
                      onTap: () => _openUri(
                        context,
                        Uri(scheme: 'tel', path: supportPhoneNormalized),
                      ),
                    ),
                  ],
                  if (supportEmail.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.small),
                    _ContactTile(
                      icon: Icons.alternate_email_rounded,
                      label:
                          '\u0628\u0631\u064a\u062f \u0627\u0644\u062f\u0639\u0645',
                      value: supportEmail,
                      onTap: () => _openUri(
                        context,
                        Uri(
                          scheme: 'mailto',
                          path: supportEmail,
                        ),
                      ),
                    ),
                  ],
                  if (socialLinks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.medium),
                    const Text(
                      '\u062d\u0633\u0627\u0628\u0627\u062a \u0627\u0644\u062a\u0648\u0627\u0635\u0644 \u0627\u0644\u0627\u062c\u062a\u0645\u0627\u0639\u064a',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final entries =
                            socialLinks.entries.toList(growable: false)
                              ..sort(
                                (a, b) => _socialOrderIndex(a.key)
                                    .compareTo(_socialOrderIndex(b.key)),
                              );
                        final columns = constraints.maxWidth >= 420 ? 3 : 2;
                        const spacing = AppSpacing.small;
                        final itemWidth =
                            (constraints.maxWidth - (columns - 1) * spacing) /
                                columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: entries.map((entry) {
                            return SizedBox(
                              width: itemWidth,
                              child: _SocialButton(
                                icon: _socialIconFor(entry.key),
                                label: _prettyPlatformName(entry.key),
                                onTap: () => _openWebUrl(context, entry.value),
                              ),
                            );
                          }).toList(growable: false),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launchedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedExternal) return;

      final launchedPlatform = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launchedPlatform) return;

      final launchedWebView = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
      if (launchedWebView) return;
    } catch (_) {}

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          '\u062a\u0639\u0630\u0631 \u0641\u062a\u062d \u0627\u0644\u0631\u0627\u0628\u0637 \u062d\u0627\u0644\u064a\u064b\u0627.',
        ),
      ),
    );
  }

  Future<void> _openWebUrl(BuildContext context, String rawUrl) async {
    final uri = _normalizeWebUri(rawUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u0631\u0627\u0628\u0637 \u063a\u064a\u0631 \u0635\u0627\u0644\u062d \u0641\u064a \u0627\u0644\u0625\u0639\u062f\u0627\u062f\u0627\u062a.',
          ),
        ),
      );
      return;
    }
    await _openUri(context, uri);
  }

  Uri? _normalizeWebUri(String rawUrl) {
    var cleaned = rawUrl.trim();
    if (cleaned.isEmpty) return null;

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.startsWith('//')) {
      cleaned = 'https:$cleaned';
    }

    Uri? uri = Uri.tryParse(cleaned);
    if (uri == null) return null;
    if (uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$cleaned');
    }
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    if (uri.host.trim().isEmpty) return null;
    return uri;
  }

  String _normalizeSupportPhone(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';

    final westernDigits = text.replaceAllMapped(
      RegExp(r'[Ù -Ù©]'),
      (m) => (m.group(0)!.codeUnitAt(0) - 1632).toString(),
    );
    final hasPlus = westernDigits.contains('+');
    final digitsOnly = westernDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return text;
    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  Map<String, String> _normalizeSocialLinks(dynamic raw) {
    if (raw == null) return const {};

    dynamic decoded = raw;
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return const {};
      try {
        decoded = jsonDecode(text);
      } catch (_) {
        return const {};
      }
    }

    if (decoded is! Map) return const {};
    final map = <String, String>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString().trim();
      final value = (entry.value ?? '').toString().trim();
      if (key.isEmpty || value.isEmpty) continue;
      final uri = _normalizeWebUri(value);
      if (uri == null) continue;
      map[key] = uri.toString();
    }
    return map;
  }

  IconData _socialIconFor(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized.contains('facebook')) return FontAwesomeIcons.facebookF;
    if (normalized.contains('instagram')) return FontAwesomeIcons.instagram;
    if (normalized.contains('twitter') || normalized == 'x') {
      return FontAwesomeIcons.twitter;
    }
    if (normalized.contains('youtube')) return FontAwesomeIcons.youtube;
    if (normalized.contains('telegram')) return FontAwesomeIcons.telegramPlane;
    if (normalized.contains('whatsapp')) return FontAwesomeIcons.whatsapp;
    if (normalized.contains('tiktok')) return FontAwesomeIcons.tiktok;
    if (normalized.contains('linkedin')) return FontAwesomeIcons.linkedinIn;
    return Icons.public_rounded;
  }

  String _prettyPlatformName(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized == 'x' || normalized.contains('twitter')) {
      return 'Twitter/X';
    }
    if (normalized.contains('facebook')) return 'Facebook';
    if (normalized.contains('instagram')) return 'Instagram';
    if (normalized.contains('youtube')) return 'YouTube';
    if (normalized.contains('telegram')) return 'Telegram';
    if (normalized.contains('whatsapp')) return 'WhatsApp';
    if (normalized.contains('tiktok')) return 'TikTok';
    if (normalized.contains('linkedin')) return 'LinkedIn';
    if (normalized.isEmpty) {
      return '\u0645\u0646\u0635\u0629';
    }
    return platform[0].toUpperCase() + platform.substring(1);
  }

  int _socialOrderIndex(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized.contains('facebook')) return 1;
    if (normalized.contains('instagram')) return 2;
    if (normalized.contains('twitter') || normalized == 'x') return 3;
    if (normalized.contains('telegram')) return 4;
    if (normalized.contains('youtube')) return 5;
    if (normalized.contains('whatsapp')) return 6;
    if (normalized.contains('tiktok')) return 7;
    if (normalized.contains('linkedin')) return 8;
    return 99;
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.forceLtr = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? const Color(0xFF171717) : Colors.white.withOpacity(0.96);
    final borderColor = AppColors.gold.withOpacity(isDark ? 0.30 : 0.20);
    final textColor = theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF776C56);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppSpacing.medium),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(AppSpacing.small),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.gold),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (forceLtr)
                        Text(
                          '\u200E$value\u200E',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        )
                      else
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xSmall),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? const Color(0xFF141414) : AppColors.gold.withOpacity(0.10);
    final borderColor = AppColors.gold.withOpacity(isDark ? 0.55 : 0.32);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(AppSpacing.medium),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 17, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.xSmall),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ø§Ù„Ø­Ø³Ø§Ø¨',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.small),
            if (!authState.isAuthenticated) ...[
              const Text(
                'Ø£Ù†Øª Ø§Ù„Ø¢Ù† ØªØªØµÙØ­ ÙƒØ¶ÙŠÙ. Ø³Ø¬Ù‘Ù„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ù„Ø­ÙØ¸ ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª ÙˆØ¥Ø¯Ø§Ø±Ø© Ù…Ù„ÙÙƒ Ø§Ù„Ø´Ø®ØµÙŠ.',
              ),
              const SizedBox(height: AppSpacing.small),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    primary: AppColors.gold,
                    onPrimary: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                      'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ / Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨'),
                ),
              ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: (authState.user?.avatarUrl ?? '').trim().isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(
                          (authState.user?.avatarUrl ?? '').trim(),
                        ),
                      )
                    : const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(authState.user?.name ?? 'Ù…Ø³ØªØ®Ø¯Ù…'),
                subtitle: Text(authState.user?.email ?? ''),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø´Ø®ØµÙŠ'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () =>
                          ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø®Ø±ÙˆØ¬'),
                ),
              ),
            ],
            if (authState.errorMessage != null &&
                authState.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                authState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (authState.message != null &&
                authState.message!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                authState.message!,
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationPreferencesSection extends ConsumerWidget {
  const _NotificationPreferencesSection({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!authState.isAuthenticated) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.notifications_off_outlined),
          title: const Text('ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª'),
          subtitle: const Text(
              'Ù‡Ø°Ù‡ Ø§Ù„Ù…ÙŠØ²Ø© Ù…ØªØ§Ø­Ø© Ø¨Ø¹Ø¯ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„.'),
          trailing: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
            child: const Text('ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„'),
          ),
        ),
      );
    }

    final categoriesAsync = ref.watch(homeCategoriesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: categoriesAsync.when(
          data: (categories) => _NotificationPreferencesEditor(
            categories: categories,
            initialValue: authState.preferences,
            isSaving: authState.preferencesLoading,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text(
              'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø£Ù‚Ø³Ø§Ù… Ù„Ø§Ø®ØªÙŠØ§Ø± ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.'),
        ),
      ),
    );
  }
}

class _NotificationPreferencesEditor extends ConsumerStatefulWidget {
  const _NotificationPreferencesEditor({
    required this.categories,
    required this.initialValue,
    required this.isSaving,
  });

  final List<CategoryModel> categories;
  final NotificationPreferencesModel initialValue;
  final bool isSaving;

  @override
  ConsumerState<_NotificationPreferencesEditor> createState() =>
      _NotificationPreferencesEditorState();
}

class _NotificationPreferencesEditorState
    extends ConsumerState<_NotificationPreferencesEditor> {
  late bool _generalEnabled;
  late bool _breakingEnabled;
  late Set<int> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _hydrateFrom(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _NotificationPreferencesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _hydrateFrom(widget.initialValue);
    }
  }

  void _hydrateFrom(NotificationPreferencesModel value) {
    _generalEnabled = value.generalEnabled;
    _breakingEnabled = value.breakingNewsEnabled;
    _selectedCategories = value.preferredCategoryIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.small),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _generalEnabled,
          onChanged: (v) => setState(() => _generalEnabled = v),
          title: const Text('Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø¹Ø§Ù…Ø©'),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _breakingEnabled,
          onChanged: (v) => setState(() => _breakingEnabled = v),
          title: const Text('Ø¥Ø´Ø¹Ø§Ø±Ø§Øª Ø§Ù„Ø£Ø®Ø¨Ø§Ø± Ø§Ù„Ø¹Ø§Ø¬Ù„Ø©'),
        ),
        const SizedBox(height: 8),
        const Text('Ø§Ù„Ø£Ù‚Ø³Ø§Ù… Ø§Ù„Ù…ÙØ¶Ù„Ø© Ù„Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª:'),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.categories.map((category) {
            final selected = _selectedCategories.contains(category.id);
            return FilterChip(
              selected: selected,
              label: Text(category.name),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedCategories.add(category.id);
                  } else {
                    _selectedCategories.remove(category.id);
                  }
                });
              },
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.isSaving
                ? null
                : () async {
                    final prefs = NotificationPreferencesModel(
                      generalEnabled: _generalEnabled,
                      breakingNewsEnabled: _breakingEnabled,
                      preferredCategoryIds:
                          _selectedCategories.toList(growable: false),
                    );
                    await ref
                        .read(authControllerProvider.notifier)
                        .savePreferences(prefs);
                  },
            icon: widget.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Ø­ÙØ¸ Ø§Ù„ØªÙØ¶ÙŠÙ„Ø§Øª'),
          ),
        ),
      ],
    );
  }
}

class _StaticPageTile extends ConsumerWidget {
  const _StaticPageTile({
    required this.title,
    required this.icon,
    required this.settingKey,
  });

  final String title;
  final IconData icon;
  final String settingKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: () async {
        final pages = await ref.read(backendServiceProvider).fetchStaticPages();
        final content = pages[settingKey]?.toString() ??
            'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø­ØªÙˆÙ‰ Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠÙ‹Ø§.';

        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _StaticPageView(title: title, content: content),
          ),
        );
      },
    );
  }
}

class _StaticPageView extends StatelessWidget {
  const _StaticPageView({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    final hasHtml = content.contains('<') && content.contains('>');
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.medium, AppSpacing.small,
            AppSpacing.medium, AppSpacing.large),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: content.trim().isEmpty
                ? const AppStateView(
                    icon: Icons.description_outlined,
                    title: 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø­ØªÙˆÙ‰',
                    message: 'Ø³ÙŠØªÙ… Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ù…Ø­ØªÙˆÙ‰ Ù„Ø§Ø­Ù‚Ù‹Ø§.',
                  )
                : hasHtml
                    ? Html(
                        data: content,
                        style: {
                          'body': Style(
                            margin: EdgeInsets.zero,
                            padding: EdgeInsets.zero,
                            lineHeight: const LineHeight(1.95),
                            fontSize: const FontSize(16),
                            color: textColor,
                          ),
                          'p': Style(color: textColor),
                          'li': Style(color: textColor),
                          'h2': Style(color: textColor),
                          'h3': Style(color: textColor),
                        },
                      )
                    : Text(content, style: theme.textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }
}
