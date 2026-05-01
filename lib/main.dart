import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/config/app_config.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/main_nav/presentation/main_nav_screen.dart';
import 'features/notifications/presentation/notifications_controller.dart';
import 'features/settings/data/settings_controller.dart';
import 'shared/services/fcm_service.dart';
import 'shared/services/service_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ArabMashreqApp()));
}

class ArabMashreqApp extends ConsumerStatefulWidget {
  const ArabMashreqApp({super.key, this.enableNotifications = true});

  final bool enableNotifications;

  @override
  ConsumerState<ArabMashreqApp> createState() => _ArabMashreqAppState();
}

class _ArabMashreqAppState extends ConsumerState<ArabMashreqApp> {
  @override
  void initState() {
    super.initState();
    if (widget.enableNotifications) {
      _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    if (kDebugMode) {
      debugPrint('[FCM] بدء إعداد الإشعارات عند تشغيل التطبيق...');
    }
    final storage = await ref.read(localStorageProvider.future);
    final deviceId = storage.getOrCreateDeviceId();
    final token = await FcmService().initialize();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint('[FCM] لم يتم تسجيل token على الخادم لأن القيمة غير متاحة.');
      }
      return;
    }
    await storage.setLastFcmToken(token);
    await ref.read(backendServiceProvider).registerFcmToken(token, deviceId);

    FirebaseMessaging.onMessage.listen((_) {
      ref.invalidate(unreadNotificationsCountProvider);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) {
      ref.invalidate(unreadNotificationsCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final safeScale = settings.fontScale.isFinite
            ? settings.fontScale.clamp(0.85, 1.35).toDouble()
            : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaleFactor: safeScale),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
