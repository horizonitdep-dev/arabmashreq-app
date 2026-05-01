import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

class LocalStorage {
  LocalStorage(this.prefs);
  final SharedPreferences prefs;

  bool getDarkMode() => prefs.getBool('dark_mode') ?? true;
  Future<void> setDarkMode(bool value) => prefs.setBool('dark_mode', value);

  double getFontScale() {
    final value = prefs.getDouble('font_scale') ?? 1.0;
    return value.clamp(0.8, 1.4).toDouble();
  }

  Future<void> setFontScale(double value) {
    final safeValue = value.isFinite ? value.clamp(0.8, 1.4).toDouble() : 1.0;
    return prefs.setDouble('font_scale', safeValue);
  }

  List<int> getBookmarks() {
    final raw = prefs.getString('bookmarks');
    if (raw == null || raw.isEmpty) return [];
    return List<int>.from(jsonDecode(raw) as List<dynamic>);
  }

  Future<void> setBookmarks(List<int> ids) =>
      prefs.setString('bookmarks', jsonEncode(ids));

  Map<int, String> getDownloadedMagazineFiles() {
    final raw = prefs.getString('magazine_downloads');
    if (raw == null || raw.isEmpty) return <int, String>{};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return map.map((key, value) => MapEntry(
            int.tryParse(key) ?? 0,
            value?.toString() ?? '',
          ))
        ..removeWhere((key, value) => key <= 0 || value.trim().isEmpty);
    } catch (_) {
      return <int, String>{};
    }
  }

  Future<void> setDownloadedMagazineFiles(Map<int, String> files) {
    final encoded = files.map((key, value) => MapEntry('$key', value));
    return prefs.setString('magazine_downloads', jsonEncode(encoded));
  }

  Future<void> setMagazineDownloadedPath(int issueId, String path) async {
    final map = getDownloadedMagazineFiles();
    map[issueId] = path;
    await setDownloadedMagazineFiles(map);
  }

  Future<void> removeMagazineDownloadedPath(int issueId) async {
    final map = getDownloadedMagazineFiles();
    map.remove(issueId);
    await setDownloadedMagazineFiles(map);
  }

  String? getAuthToken() {
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<void> setAuthToken(String token) =>
      prefs.setString('auth_token', token);
  Future<void> clearAuthToken() => prefs.remove('auth_token');

  Map<String, dynamic>? getAuthUser() {
    final raw = prefs.getString('auth_user');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setAuthUser(Map<String, dynamic> userJson) {
    return prefs.setString('auth_user', jsonEncode(userJson));
  }

  Future<void> clearAuthUser() => prefs.remove('auth_user');

  Future<void> clearAuthSession() async {
    await clearAuthToken();
    await clearAuthUser();
  }

  String getOrCreateDeviceId() {
    final existing = prefs.getString('device_id');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final randomPart = Random().nextInt(1 << 32).toRadixString(16);
    final generated =
        'device-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
    prefs.setString('device_id', generated);
    return generated;
  }

  String? getLastFcmToken() {
    final value = prefs.getString('last_fcm_token');
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setLastFcmToken(String token) =>
      prefs.setString('last_fcm_token', token);
}

final localStorageProvider = FutureProvider<LocalStorage>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return LocalStorage(prefs);
});
