import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final wordpressDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.wordpressBaseUrl,
    connectTimeout: 15000,
    receiveTimeout: 20000,
  ));
});

final backendDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.backendBaseUrl,
    connectTimeout: 15000,
    receiveTimeout: 20000,
    headers: {'Accept': 'application/json'},
  ));
});
