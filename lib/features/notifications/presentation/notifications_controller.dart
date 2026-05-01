import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_notification_model.dart';
import '../../../shared/services/api_exception.dart';
import '../../../shared/services/service_providers.dart';
import '../../auth/data/auth_controller.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const <AppNotificationModel>[],
    this.loading = false,
    this.loadingMore = false,
    this.errorMessage,
    this.page = 1,
    this.hasMore = true,
    this.unreadCount = 0,
  });

  final List<AppNotificationModel> items;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;
  final int page;
  final bool hasMore;
  final int unreadCount;

  NotificationsState copyWith({
    List<AppNotificationModel>? items,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    int? page,
    bool? hasMore,
    int? unreadCount,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this.ref) : super(const NotificationsState());

  final Ref ref;

  Future<void> loadInitial() async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      state = const NotificationsState();
      return;
    }

    state =
        state.copyWith(loading: true, clearError: true, page: 1, hasMore: true);
    try {
      final service = ref.read(backendServiceProvider);
      final items = await service.fetchNotifications(page: 1);
      final unreadCount = await service.fetchUnreadNotificationsCount();
      state = state.copyWith(
        items: items,
        loading: false,
        page: 1,
        hasMore: items.length >= 20,
        unreadCount: unreadCount,
      );
      ref.invalidate(unreadNotificationsCountProvider);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } catch (_) {
      state =
          state.copyWith(loading: false, errorMessage: 'تعذر تحميل الإشعارات.');
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;

    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final rows = await ref
          .read(backendServiceProvider)
          .fetchNotifications(page: nextPage);
      state = state.copyWith(
        loadingMore: false,
        page: nextPage,
        hasMore: rows.length >= 20,
        items: [...state.items, ...rows],
      );
    } on ApiException catch (e) {
      state = state.copyWith(loadingMore: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
          loadingMore: false, errorMessage: 'تعذر تحميل المزيد من الإشعارات.');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) return;

    final item = state.items.firstWhere(
      (n) => n.id == notificationId,
      orElse: () =>
          const AppNotificationModel(id: 0, title: '', body: '', payload: {}),
    );
    if (item.id == 0 || item.isRead) return;

    final now = DateTime.now();
    final updated = state.items
        .map((n) => n.id == notificationId
            ? AppNotificationModel(
                id: n.id,
                title: n.title,
                body: n.body,
                payload: n.payload,
                readAt: now,
                createdAt: n.createdAt,
              )
            : n)
        .toList(growable: false);

    state = state.copyWith(
      items: updated,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    try {
      await ref
          .read(backendServiceProvider)
          .markNotificationsRead([notificationId]);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {
      // Keep UI stable even if request fails.
    }
  }

  Future<void> clearAll() async {
    final authState = ref.read(authControllerProvider);
    if (!authState.isAuthenticated) return;

    try {
      await ref.read(backendServiceProvider).clearNotifications();
      state = state.copyWith(
        items: const <AppNotificationModel>[],
        unreadCount: 0,
        page: 1,
        hasMore: false,
        clearError: true,
      );
      ref.invalidate(unreadNotificationsCountProvider);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'تعذر حذف الإشعارات.');
    }
  }
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (!authState.isAuthenticated) return 0;
  return ref.watch(backendServiceProvider).fetchUnreadNotificationsCount();
});
