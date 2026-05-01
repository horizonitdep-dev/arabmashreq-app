import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/breaking_news_model.dart';
import '../../home/data/home_providers.dart';

final breakingNewsPageProvider = FutureProvider.autoDispose<List<BreakingNewsModel>>((ref) async {
  // Use the same source/provider behavior as the home ticker to keep both screens consistent.
  return ref.watch(breakingTickerProvider.future);
});
