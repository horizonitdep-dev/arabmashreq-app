import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final wordpressDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.wordpressBaseUrl,
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 20000),
  ));
});

final backendDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.backendBaseUrl,
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 20000),
    headers: {'Accept': 'application/json'},
  ));
});
