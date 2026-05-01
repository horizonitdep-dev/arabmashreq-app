import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_notification_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/widgets/states/app_state_view.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../breaking_news/presentation/breaking_news_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../home/data/home_providers.dart';
import 'notifications_controller.dart';

const notificationsTitle = 'الإشعارات';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsControllerProvider.notifier).loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final state = ref.watch(notificationsControllerProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text(notificationsTitle)),
        body: AppStateView(
          icon: Icons.notifications_off_outlined,
          title: 'تسجيل الدخول مطلوب',
          message: 'سجّل الدخول لعرض صندوق الإشعارات الخاص بك.',
          actionLabel: 'تسجيل الدخول',
          onAction: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AuthScreen()));
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(notificationsTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: IconButton(
              tooltip: 'مسح الكل',
              icon: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.delete_sweep_outlined, size: 20),
              ),
              onPressed: state.items.isEmpty
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('حذف الإشعارات'),
                          content: const Text(
                            'هل تريد حذف جميع الإشعارات من هذا الجهاز؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف الكل'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref
                            .read(notificationsControllerProvider.notifier)
                            .clearAll();
                      }
                    },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsControllerProvider.notifier).refresh(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null && state.items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.72,
                        child: AppStateView(
                          icon: Icons.error_outline,
                          title: 'تعذر تحميل الإشعارات',
                          message: state.errorMessage!,
                          actionLabel: 'إعادة المحاولة',
                          onAction: () => ref
                              .read(notificationsControllerProvider.notifier)
                              .loadInitial(),
                        ),
                      ),
                    ],
                  )
                : state.items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(
                            height: 460,
                            child: AppStateView(
                              icon: Icons.notifications_none_rounded,
                              title: 'لا توجد إشعارات',
                              message:
                                  'ستظهر الإشعارات هنا بعد إرسالها من لوحة التحكم.',
                            ),
                          ),
                        ],
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.extentAfter < 260) {
                            ref
                                .read(notificationsControllerProvider.notifier)
                                .loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
                          itemCount:
                              state.items.length + (state.loadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final item = state.items[index];
                            return _NotificationCard(
                              item: item,
                              onTap: () => _openNotification(item),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Future<void> _openNotification(AppNotificationModel item) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .markAsRead(item.id);
    if (!mounted) return;

    final articleId = item.articleId;
    if (articleId != null && articleId > 0) {
      context.push('/article/$articleId');
      return;
    }

    final categoryId = item.categoryId;
    if (categoryId != null && categoryId > 0) {
      final categories = await ref.read(homeCategoriesProvider.future);
      if (!mounted) return;
      final selected =
          categories.where((c) => c.id == categoryId).toList(growable: false);
      if (selected.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryDetailsScreen(category: selected.first),
          ),
        );
        return;
      }

      final fallbackCategory =
          CategoryModel(id: categoryId, name: 'القسم #$categoryId');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailsScreen(category: fallbackCategory),
        ),
      );
      return;
    }

    final isBreaking =
        item.screen == 'breaking_news' || item.breakingNewsId != null;
    if (isBreaking) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const BreakingNewsScreen()));
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final AppNotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? theme.dividerColor
                  : theme.colorScheme.secondary.withOpacity(0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: item.isRead
                    ? theme.colorScheme.secondary.withOpacity(0.14)
                    : theme.colorScheme.secondary.withOpacity(0.22),
                child: Icon(
                  item.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_rounded,
                  color: theme.colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsetsDirectional.only(start: 8),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(item.createdAt!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y/$m/$d - $hh:$mm';
  }
}
