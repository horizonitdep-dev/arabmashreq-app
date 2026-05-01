import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';

class SettingsState {
  const SettingsState({required this.isDarkMode, required this.fontScale});

  final bool isDarkMode;
  final double fontScale;

  SettingsState copyWith({bool? isDarkMode, double? fontScale}) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this.ref)
      : super(const SettingsState(isDarkMode: true, fontScale: 1.0));

  final Ref ref;

  Future<void> load() async {
    final storage = await ref.read(localStorageProvider.future);
    final safeScale = storage.getFontScale().clamp(0.8, 1.4).toDouble();
    state = state.copyWith(
      isDarkMode: storage.getDarkMode(),
      fontScale: safeScale,
    );
  }

  Future<void> toggleDarkMode(bool value) async {
    final storage = await ref.read(localStorageProvider.future);
    await storage.setDarkMode(value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> updateFontScale(double value) async {
    final storage = await ref.read(localStorageProvider.future);
    final safeValue = value.isFinite ? value.clamp(0.8, 1.4).toDouble() : 1.0;
    await storage.setFontScale(safeValue);
    state = state.copyWith(fontScale: safeValue);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final c = SettingsController(ref);
  c.load();
  return c;
});

final appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsControllerProvider).isDarkMode
      ? ThemeMode.dark
      : ThemeMode.light;
});
