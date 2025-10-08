import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Settings model
class AppSettings {
  final ThemeMode themeMode;
  final double fontSize;

  const AppSettings({
    required this.themeMode,
    required this.fontSize,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontSize,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

// Settings repository
class SettingsRepository {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 16.0;
    
    return AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      fontSize: fontSize,
    );
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, themeMode.index);
  }

  Future<void> saveFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }
}

// Provider for settings repository
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// Provider for app settings
final appSettingsProvider = AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});

// Settings notifier
class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    return await repository.loadSettings();
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      final newSettings = currentSettings.copyWith(themeMode: themeMode);
      
      state = AsyncValue.data(newSettings);
      
      final repository = ref.read(settingsRepositoryProvider);
      await repository.saveThemeMode(themeMode);
    }
  }

  Future<void> updateFontSize(double fontSize) async {
    if (state.hasValue) {
      final currentSettings = state.value!;
      final newSettings = currentSettings.copyWith(fontSize: fontSize);
      
      state = AsyncValue.data(newSettings);
      
      final repository = ref.read(settingsRepositoryProvider);
      await repository.saveFontSize(fontSize);
    }
  }
}

// Convenience providers for individual settings
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.when(
    data: (settings) => settings.themeMode,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});

final fontSizeProvider = Provider<double>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return settings.when(
    data: (settings) => settings.fontSize,
    loading: () => 16.0,
    error: (_, __) => 16.0,
  );
});