import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class SettingsService {
  static const _kEngine = 'extractor_engine'; // 'youtube_explode' | 'yt_dlp'
  static const _kLastFormatLabel = 'last_format_label';
  static const _kThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _kAccent = 'accent';
  static const _kOnboarded = 'onboarded';

  Future<String> engine() async =>
      (await SharedPreferences.getInstance()).getString(_kEngine) ?? 'youtube_explode';
  Future<void> setEngine(String v) async =>
      (await SharedPreferences.getInstance()).setString(_kEngine, v);

  // Label du dernier format choisi (ex "MP3 128kbps") -> badge "Dernier utilisé".
  Future<String?> lastFormatLabel() async =>
      (await SharedPreferences.getInstance()).getString(_kLastFormatLabel);
  Future<void> setLastFormatLabel(String label) async =>
      (await SharedPreferences.getInstance()).setString(_kLastFormatLabel, label);

  Future<ThemeMode> themeMode() async {
    final v = (await SharedPreferences.getInstance()).getString(_kThemeMode);
    return switch (v) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system };
  }
  Future<void> setThemeMode(ThemeMode m) async =>
      (await SharedPreferences.getInstance()).setString(_kThemeMode, m.name);

  Future<Color> accent() async {
    final v = (await SharedPreferences.getInstance()).getInt(_kAccent);
    return v == null ? kAccentDefault : Color(v);
  }
  Future<void> setAccent(Color c) async =>
      (await SharedPreferences.getInstance()).setInt(_kAccent, c.toARGB32());

  Future<bool> onboarded() async =>
      (await SharedPreferences.getInstance()).getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() async =>
      (await SharedPreferences.getInstance()).setBool(_kOnboarded, true);
}
