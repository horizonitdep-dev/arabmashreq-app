import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/ad_model.dart';
import '../models/app_notification_model.dart';
import '../models/auth_user_model.dart';
import '../models/breaking_news_model.dart';
import '../models/comment_model.dart';
import '../models/magazine_issue_model.dart';
import '../models/notification_preferences_model.dart';
import '../models/user_profile_model.dart';
import 'api_exception.dart';

class AuthResponseModel {
  const AuthResponseModel(
      {required this.token, required this.user, required this.message});

  final String token;
  final AuthUserModel user;
  final String message;
}

class BackendService {
  BackendService(this._dio);

  final Dio _dio;

  String? token;

  void setToken(String? value) {
    token = value;
    if (value != null && value.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $value';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['user'] ?? <String, dynamic>{}) as Map);
      return AuthResponseModel(
        token: (data['token'] ?? '').toString(),
        user: AuthUserModel.fromJson(userJson),
        message: (data['message'] ?? 'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¨Ù†Ø¬Ø§Ø­.')
            .toString(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„.');
    }
  }

  Future<AuthResponseModel> googleLogin({
    required String idToken,
    String? accessToken,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post('/auth/google', data: {
        'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
        'device_name': deviceName,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['user'] ?? <String, dynamic>{}) as Map);
      return AuthResponseModel(
        token: (data['token'] ?? '').toString(),
        user: AuthUserModel.fromJson(userJson),
        message: (data['message'] ??
                'ØªÙ… ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¹Ø¨Ø± Google Ø¨Ù†Ø¬Ø§Ø­.')
            .toString(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ Ø¹Ø¨Ø± Google.');
    }
  }

  Future<AuthResponseModel> appleLogin({
    required String identityToken,
    required String authorizationCode,
    String? userIdentifier,
    String? email,
    String? fullName,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post('/auth/apple', data: {
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
        if (userIdentifier != null && userIdentifier.isNotEmpty)
          'user_identifier': userIdentifier,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        'device_name': deviceName,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['user'] ?? <String, dynamic>{}) as Map);
      return AuthResponseModel(
        token: (data['token'] ?? '').toString(),
        user: AuthUserModel.fromJson(userJson),
        message: (data['message'] ??
                '\u062a\u0645 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0639\u0628\u0631 Apple \u0628\u0646\u062c\u0627\u062d.')
            .toString(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage:
              '\u062a\u0639\u0630\u0631 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0639\u0628\u0631 Apple.');
    }
  }

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['user'] ?? <String, dynamic>{}) as Map);
      return AuthResponseModel(
        token: (data['token'] ?? '').toString(),
        user: AuthUserModel.fromJson(userJson),
        message: (data['message'] ?? 'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨ Ø¨Ù†Ø¬Ø§Ø­.')
            .toString(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„Ø­Ø³Ø§Ø¨.');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // Ignore server-side failure and clear session locally.
    }
  }

  Future<AuthUserModel> fetchProfile() async {
    try {
      final response = await _dio.get('/profile');
      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['data'] ?? <String, dynamic>{}) as Map);
      return AuthUserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø´Ø®ØµÙŠ.');
    }
  }

  Future<NotificationPreferencesModel> fetchUserPreferences() async {
    try {
      final response = await _dio.get('/user/preferences');
      final data = Map<String, dynamic>.from(response.data as Map);
      final prefsJson = Map<String, dynamic>.from(
          (data['data'] ?? <String, dynamic>{}) as Map);
      return NotificationPreferencesModel.fromJson(prefsJson);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage:
              'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.');
    }
  }

  Future<NotificationPreferencesModel> updateUserPreferences(
      NotificationPreferencesModel prefs) async {
    try {
      final response =
          await _dio.put('/user/preferences', data: prefs.toJson());
      final data = Map<String, dynamic>.from(response.data as Map);
      final prefsJson = Map<String, dynamic>.from(
          (data['data'] ?? <String, dynamic>{}) as Map);
      return NotificationPreferencesModel.fromJson(prefsJson);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage:
              'ØªØ¹Ø°Ø± Ø­ÙØ¸ ØªÙØ¶ÙŠÙ„Ø§Øª Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.');
    }
  }

  Future<List<BreakingNewsModel>> fetchBreakingNews() async {
    try {
      final response = await _dio.get('/breaking-news');
      final raw = response.data;
      final dynamic payload =
          raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      final list = payload is List ? payload : <dynamic>[];
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(BreakingNewsModel.fromJson)
          .where((item) => item.id > 0 && item.title.trim().isNotEmpty)
          .toList();

      if (kDebugMode) {
        debugPrint('[BREAKING] items fetched: ${items.length}');
      }

      return items;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[BREAKING] fetch failed: ${e.response?.statusCode ?? 'no_status'}');
      }
      throw _mapDioException(e,
          fallbackMessage:
              'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø£Ø®Ø¨Ø§Ø± Ø§Ù„Ø¹Ø§Ø¬Ù„Ø©.');
    }
  }

  Future<UserProfileModel> fetchProfileDetails() async {
    try {
      final response = await _dio.get('/profile');
      final data = Map<String, dynamic>.from(response.data as Map);
      final profileJson = Map<String, dynamic>.from(
          (data['data'] ?? <String, dynamic>{}) as Map);
      return UserProfileModel.fromJson(profileJson);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø­Ø³Ø§Ø¨.');
    }
  }

  Future<AuthUserModel> updateProfile({
    required String name,
    String? avatarUrl,
    String? avatarFilePath,
    bool removeAvatar = false,
  }) async {
    try {
      final formPayload = <String, dynamic>{
        '_method': 'PUT',
        'name': name,
        if (removeAvatar) 'remove_avatar': 1,
      };

      if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
        formPayload['avatar_url'] = avatarUrl.trim();
      }

      if (avatarFilePath != null && avatarFilePath.trim().isNotEmpty) {
        formPayload['avatar'] = await MultipartFile.fromFile(avatarFilePath);
      }

      final formData = FormData.fromMap(formPayload);

      final response = await _dio.post('/profile/update', data: formData);
      final data = Map<String, dynamic>.from(response.data as Map);
      final userJson = Map<String, dynamic>.from(
          (data['data'] ?? <String, dynamic>{}) as Map);
      return AuthUserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ø¯ÙŠØ« Ø§Ù„Ù…Ù„Ù Ø§Ù„Ø´Ø®ØµÙŠ.');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      await _dio.post('/profile/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØºÙŠÙŠØ± ÙƒÙ„Ù…Ø© Ø§Ù„Ù…Ø±ÙˆØ±.');
    }
  }

  Future<void> deleteAccount({String? password}) async {
    try {
      final payload = <String, dynamic>{};
      if (password != null && password.trim().isNotEmpty) {
        payload['password'] = password.trim();
      }
      await _dio.delete('/profile/delete-account', data: payload);
    } on DioException catch (e) {
      throw _mapDioException(e, fallbackMessage: 'ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ø­Ø³Ø§Ø¨.');
    }
  }

  Future<List<AdModel>> fetchAds(String placement) async {
    try {
      final response =
          await _dio.get('/ads', queryParameters: {'placement': placement});
      final raw = response.data;
      final dynamic payload =
          raw is Map<String, dynamic> ? (raw['data'] ?? raw) : raw;
      final list = payload is List ? payload : <dynamic>[];
      final items =
          list.whereType<Map<String, dynamic>>().map(AdModel.fromJson).toList();

      if (kDebugMode) {
        debugPrint('[ADS] placement=$placement, items=${items.length}');
      }

      return items;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[ADS] placement=$placement, failed=${e.response?.statusCode ?? 'no_status'}');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ADS] placement=$placement, failed=$e');
      }
      return [];
    }
  }

  Future<void> trackArticleOpen(
      {required int articleId, required String title}) async {
    try {
      await _dio.post('/analytics/events/article-open', data: {
        'wp_article_id': articleId,
        'article_title': title,
        'source': 'mobile_app',
      });
    } catch (_) {}
  }

  Future<void> trackAdImpression(int adId) async {
    try {
      await _dio.post('/analytics/events/ad-event', data: {
        'ad_id': adId,
        'event_type': 'impression',
      });
    } catch (_) {}
  }

  Future<void> trackAdClick(int adId) async {
    try {
      await _dio.post('/analytics/events/ad-event', data: {
        'ad_id': adId,
        'event_type': 'click',
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> fetchAppSettings() async {
    try {
      final response = await _dio.get('/settings');
      final raw = response.data;
      final data =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final rows = (data['data'] ?? const <dynamic>[]) as List<dynamic>;

      final parsed = <String, dynamic>{};
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final key = (row['key'] ?? '').toString().trim();
        if (key.isEmpty) continue;
        final type = (row['type'] ?? '').toString().trim().toLowerCase();
        parsed[key] = _decodeSettingValue(row['value'], type);
      }

      return parsed;
    } on DioException catch (e) {
      throw _mapDioException(
        e,
        fallbackMessage:
            '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0625\u0639\u062f\u0627\u062f\u0627\u062a \u0627\u0644\u062a\u0637\u0628\u064a\u0642.',
      );
    }
  }

  Future<Map<String, dynamic>> fetchStaticPages() async {
    try {
      final response = await _dio.get('/settings/static-pages');
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return {
        'about_us': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø­ØªÙˆÙ‰ Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠØ§Ù‹.',
        'team': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø­ØªÙˆÙ‰ Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠØ§Ù‹.',
        'privacy_policy': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø­ØªÙˆÙ‰ Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠØ§Ù‹.',
      };
    }
  }

  Future<void> registerFcmToken(String token, String deviceId) async {
    try {
      if (kDebugMode) {
        final tokenPrefix =
            token.substring(0, token.length > 18 ? 18 : token.length);
        debugPrint('[FCM] Ø¥Ø±Ø³Ø§Ù„ token Ø¥Ù„Ù‰ /fcm-tokens Ù„Ù„Ø¬Ù‡Ø§Ø²: ');
        debugPrint('[FCM] Token Prefix (register): $tokenPrefix...');
      }
      await _dio.post('/fcm-tokens', data: {
        'fcm_token': token,
        'device_id': deviceId,
        'platform': 'mobile',
      });
      if (kDebugMode) {
        debugPrint(
            '[FCM] ØªÙ… Ø¥Ø±Ø³Ø§Ù„ token Ø¥Ù„Ù‰ Ø§Ù„Ø®Ø§Ø¯Ù… Ø¨Ù†Ø¬Ø§Ø­.');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[FCM] ÙØ´Ù„ Ø¥Ø±Ø³Ø§Ù„ token Ø¥Ù„Ù‰ Ø§Ù„Ø®Ø§Ø¯Ù…: ${e.response?.statusCode ?? 'no_status'}');
        debugPrint('[FCM] ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø®Ø·Ø£: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] ÙØ´Ù„ Ø¥Ø±Ø³Ø§Ù„ token Ø¥Ù„Ù‰ Ø§Ù„Ø®Ø§Ø¯Ù…: $e');
      }
    }
  }

  Future<List<CommentModel>> fetchCommentsByArticle(int articleId) async {
    try {
      final response = await _dio.get('/comments/article/$articleId');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['data'] ?? <dynamic>[]) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map(CommentModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªØ¹Ù„ÙŠÙ‚Ø§Øª.');
    }
  }

  Future<void> createComment({
    required int articleId,
    required String content,
  }) async {
    try {
      await _dio.post('/comments/create', data: {
        'article_id': articleId,
        'content': content,
      });
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø¥Ø¶Ø§ÙØ© Ø§Ù„ØªØ¹Ù„ÙŠÙ‚.');
    }
  }

  Future<void> replyToComment({
    required int articleId,
    required int parentId,
    required String content,
  }) async {
    try {
      await _dio.post('/comments/reply', data: {
        'article_id': articleId,
        'parent_id': parentId,
        'content': content,
      });
    } on DioException catch (e) {
      throw _mapDioException(e, fallbackMessage: 'ØªØ¹Ø°Ø± Ø¥Ø¶Ø§ÙØ© Ø§Ù„Ø±Ø¯.');
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('/comments/delete', data: {
        'comment_id': commentId,
      }, queryParameters: {
        'comment_id': commentId,
      });
    } on DioException catch (_) {
      // Some backends/proxies may drop DELETE request bodies.
      // Fallback to method override so deletion still works.
      try {
        await _dio.post('/comments/delete', data: {
          '_method': 'DELETE',
          'comment_id': commentId,
        });
        return;
      } on DioException catch (fallbackError) {
        throw _mapDioException(
          fallbackError,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„ØªØ¹Ù„ÙŠÙ‚.',
        );
      }
    }
  }

  Future<void> reportComment({
    required int commentId,
    required String reason,
  }) async {
    try {
      await _dio.post('/comments/report', data: {
        'comment_id': commentId,
        'reason': reason,
      });
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„Ø¨Ù„Ø§Øº.');
    }
  }

  Future<int> fetchArticleLikesCount(int articleId) async {
    try {
      final response = await _dio.get('/articles/$articleId/likes-count');
      final data = Map<String, dynamic>.from(response.data as Map);
      return int.tryParse((data['likes_count'] ?? 0).toString()) ?? 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  Future<bool> fetchArticleLikedByUser(int articleId) async {
    try {
      final response = await _dio.get('/articles/$articleId/liked-by-user');
      final data = Map<String, dynamic>.from(response.data as Map);
      return data['liked_by_user'] == true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<void> likeArticle(int articleId) async {
    try {
      await _dio.post('/articles/like', data: {'article_id': articleId});
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¥Ø¹Ø¬Ø§Ø¨.');
    }
  }

  Future<void> unlikeArticle(int articleId) async {
    try {
      await _dio.post('/articles/unlike', data: {'article_id': articleId});
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø¥Ø¹Ø¬Ø§Ø¨.');
    }
  }

  Future<List<AppNotificationModel>> fetchNotifications({int page = 1}) async {
    try {
      final response =
          await _dio.get('/notifications', queryParameters: {'page': page});
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['data'] ?? <dynamic>[]) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map(AppNotificationModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.');
    }
  }

  Future<void> markNotificationsRead(List<int> notificationIds) async {
    try {
      await _dio.post('/notifications/read', data: {
        if (notificationIds.isNotEmpty) 'notification_ids': notificationIds,
      });
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ø¯ÙŠØ« Ø­Ø§Ù„Ø© Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.');
    }
  }

  Future<void> clearNotifications({List<int>? notificationIds}) async {
    try {
      await _dio.delete('/notifications/clear', data: {
        if (notificationIds != null && notificationIds.isNotEmpty)
          'notification_ids': notificationIds,
      });
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± Ø­Ø°Ù Ø§Ù„Ø¥Ø´Ø¹Ø§Ø±Ø§Øª.');
    }
  }

  Future<List<MagazineIssueModel>> fetchMagazineIssues({int page = 1}) async {
    try {
      final response =
          await _dio.get('/magazine/issues', queryParameters: {'page': page});
      final raw = response.data;
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(MagazineIssueModel.fromJson)
            .toList(growable: false);
      }
      final data = Map<String, dynamic>.from(raw as Map);
      final rows = (data['data'] ?? <dynamic>[]) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map(MagazineIssueModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø£Ø¹Ø¯Ø§Ø¯ Ø§Ù„Ù…Ø¬Ù„Ø©.');
    }
  }

  Future<MagazineIssueModel> fetchMagazineIssue(int issueId) async {
    try {
      final response = await _dio.get('/magazine/issues/$issueId');
      final data = Map<String, dynamic>.from(response.data as Map);
      final json = Map<String, dynamic>.from(
        (data['data'] ?? <String, dynamic>{}) as Map,
      );
      return MagazineIssueModel.fromJson(json);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¹Ø¯Ø¯.');
    }
  }

  Future<MagazineIssueModel?> fetchFeaturedMagazineIssue() async {
    try {
      final response = await _dio.get('/magazine/featured');
      final data = Map<String, dynamic>.from(response.data as Map);
      final raw = data['data'];
      if (raw is! Map<String, dynamic>) return null;
      return MagazineIssueModel.fromJson(raw);
    } on DioException catch (_) {
      return null;
    }
  }

  Future<void> trackMagazineDownload(int issueId) async {
    try {
      await _dio.post('/magazine/issues/$issueId/download-track', data: {
        'source': 'mobile_app',
      });
    } on DioException catch (_) {
      // Ignore analytics failure to keep UX smooth.
    }
  }

  Future<void> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final downloadDio = Dio(
        BaseOptions(
          headers: Map<String, dynamic>.from(_dio.options.headers),
          connectTimeout: const Duration(milliseconds: 30000),
          receiveTimeout: null,
          sendTimeout: null,
          followRedirects: true,
          maxRedirects: 5,
        ),
      );

      await downloadDio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw _mapDioException(e, fallbackMessage: 'ØªØ¹Ø°Ø± ØªÙ†Ø²ÙŠÙ„ Ø§Ù„Ù…Ù„Ù.');
    }
  }

  Future<int> fetchUnreadNotificationsCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      final data = Map<String, dynamic>.from(response.data as Map);
      return int.tryParse((data['unread_count'] ?? 0).toString()) ?? 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyComments() async {
    try {
      final response = await _dio.get('/profile/comments');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['data'] ?? <dynamic>[]) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ ØªØ¹Ù„ÙŠÙ‚Ø§ØªÙƒ.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyLikes() async {
    try {
      final response = await _dio.get('/profile/likes');
      final data = Map<String, dynamic>.from(response.data as Map);
      final rows = (data['data'] ?? <dynamic>[]) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    } on DioException catch (e) {
      throw _mapDioException(e,
          fallbackMessage: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø¥Ø¹Ø¬Ø§Ø¨Ø§ØªÙƒ.');
    }
  }

  ApiException _mapDioException(DioException error, {required String fallbackMessage}) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (response == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return ApiException(
          message:
              'ØªØ¹Ø°Ø± Ø§Ù„Ø§ØªØµØ§Ù„ Ø¨Ø§Ù„Ø®Ø§Ø¯Ù…. ØªØ­Ù‚Ù‚ Ù…Ù† Ø§ØªØµØ§Ù„ Ø§Ù„Ø¥Ù†ØªØ±Ù†Øª ÙˆÙ…Ù† Ø¥Ø¹Ø¯Ø§Ø¯ API_BASE_URL Ø§Ù„ØµØ­ÙŠØ­.',
        );
      }
    }

    if (data is Map) {
      final map = Map<String, dynamic>.from(data.cast<String, dynamic>());
      final message = (map['message'] ?? fallbackMessage).toString();
      final errorsRaw = map['errors'];
      if (errorsRaw is Map) {
        final errors = <String, String>{};
        errorsRaw.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            errors[key.toString()] = value.first.toString();
          } else if (value != null) {
            errors[key.toString()] = value.toString();
          }
        });
        return ApiException(
            message: message, fieldErrors: errors, statusCode: statusCode);
      }
      return ApiException(message: message, statusCode: statusCode);
    }

    return ApiException(message: fallbackMessage, statusCode: statusCode);
  }

  dynamic _decodeSettingValue(dynamic value, String type) {
    if (type == 'json') {
      if (value is Map || value is List) return value;

      final raw = (value ?? '').toString().trim();
      if (raw.isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(raw);
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    if (type == 'boolean') {
      final raw = (value ?? '').toString().trim().toLowerCase();
      return raw == '1' || raw == 'true' || raw == 'yes';
    }

    return value;
  }
}
