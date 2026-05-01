import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_providers.dart';
import 'backend_service.dart';
import 'wordpress_service.dart';

final wordpressServiceProvider = Provider<WordpressService>((ref) {
  return WordpressService(ref.watch(wordpressDioProvider));
});

final backendServiceProvider = Provider<BackendService>((ref) {
  return BackendService(ref.watch(backendDioProvider));
});
