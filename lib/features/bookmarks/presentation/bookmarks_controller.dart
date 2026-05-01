import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';

class BookmarksController extends StateNotifier<List<int>> {
  BookmarksController(this.ref) : super([]) {
    load();
  }

  final Ref ref;

  Future<void> load() async {
    final storage = await ref.read(localStorageProvider.future);
    state = storage.getBookmarks();
  }

  Future<void> toggle(int articleId) async {
    final storage = await ref.read(localStorageProvider.future);
    final current = [...state];
    if (current.contains(articleId)) {
      current.remove(articleId);
    } else {
      current.add(articleId);
    }
    await storage.setBookmarks(current);
    state = current;
  }
}

final bookmarksControllerProvider = StateNotifierProvider<BookmarksController, List<int>>(
  (ref) => BookmarksController(ref),
);
