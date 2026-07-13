import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FcmService {
  Future<String?> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

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
        } else {
          debugPrint('[FCM] لم يتم الحصول على FCM token (null/empty).');
        }
      }

      messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          debugPrint('[FCM] Token refreshed: $newToken');
        }
      });

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] فشل تهيئة Firebase/FCM: $e');
      }
      return null;
    }
  }
}
