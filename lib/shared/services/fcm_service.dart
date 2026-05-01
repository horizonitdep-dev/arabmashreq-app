import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  Future<String?> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('[FCM] بدء تهيئة Firebase...');
      }
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        if (kDebugMode) {
          debugPrint('[FCM] تم تهيئة Firebase بنجاح.');
        }
      } else if (kDebugMode) {
        debugPrint('[FCM] Firebase مهيأ مسبقاً.');
      }

      final messaging = FirebaseMessaging.instance;

      // On iOS/macOS and newer Android versions this call is safe; it may be a no-op otherwise.
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (!kIsWeb && Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      if (kDebugMode) {
        if (token != null && token.isNotEmpty) {
          debugPrint('[FCM] تم الحصول على FCM token بنجاح.');
          debugPrint('[FCM] Token Prefix: ${token.substring(0, token.length > 18 ? 18 : token.length)}...');
        } else {
          debugPrint('[FCM] لم يتم الحصول على FCM token (null/empty).');
        }
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] فشل تهيئة Firebase/FCM: $e');
      }
      // Placeholder-safe fallback: app stays functional even when Firebase config/permissions are missing.
      return null;
    }
  }
}
