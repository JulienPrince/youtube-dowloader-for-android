import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_format.dart';
import '../theme/app_theme.dart';

/// Format pré-choisi pour le bouton Télécharger.
enum DefaultFormat { ask, mp4, mp3 }

class SettingsService {
  static const _kEngine = 'extractor_engine'; // 'youtube_explode' | 'yt_dlp'
  static const _kLastFormatLabel = 'last_format_label';
  static const _kThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _kAccent = 'accent';
  static const _kOnboarded = 'onboarded';
  static const _kDefaultFormat = 'default_format'; // ask|mp4|mp3
  static const _kAudioKbps = 'audio_kbps'; // 320|256|192|128
  static const _kMaxVideo = 'max_video'; // 1080|720|360 (0 = meilleure)
  static const _kMusicDir = 'music_dir'; // chemin custom ou null
  static const _kVideoDir = 'video_dir';

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

  Future<DefaultFormat> defaultFormat() async {
    final v = (await SharedPreferences.getInstance()).getString(_kDefaultFormat);
    return switch (v) {
      'mp4' => DefaultFormat.mp4,
      'mp3' => DefaultFormat.mp3,
      _ => DefaultFormat.ask,
    };
  }
  Future<void> setDefaultFormat(DefaultFormat f) async =>
      (await SharedPreferences.getInstance()).setString(_kDefaultFormat, f.name);

  /// Bitrate MP3 cible (kbps) appliqué par FFmpeg.
  Future<int> audioKbps() async =>
      (await SharedPreferences.getInstance()).getInt(_kAudioKbps) ?? 320;
  Future<void> setAudioKbps(int kbps) async =>
      (await SharedPreferences.getInstance()).setInt(_kAudioKbps, kbps);

  /// Hauteur vidéo max (1080/720/360 ; 0 = meilleure dispo).
  Future<int> maxVideoHeight() async =>
      (await SharedPreferences.getInstance()).getInt(_kMaxVideo) ?? 1080;
  Future<void> setMaxVideoHeight(int h) async =>
      (await SharedPreferences.getInstance()).setInt(_kMaxVideo, h);

  Future<String?> musicDir() async =>
      (await SharedPreferences.getInstance()).getString(_kMusicDir);
  Future<void> setMusicDir(String? path) async {
    final p = await SharedPreferences.getInstance();
    path == null ? await p.remove(_kMusicDir) : await p.setString(_kMusicDir, path);
  }

  Future<String?> videoDir() async =>
      (await SharedPreferences.getInstance()).getString(_kVideoDir);
  Future<void> setVideoDir(String? path) async {
    final p = await SharedPreferences.getInstance();
    path == null ? await p.remove(_kVideoDir) : await p.setString(_kVideoDir, path);
  }

  DownloadFormat? defaultDownloadFormat(DefaultFormat f) => switch (f) {
        DefaultFormat.mp4 => DownloadFormat.mp4,
        DefaultFormat.mp3 => DownloadFormat.mp3,
        DefaultFormat.ask => null,
      };
}
