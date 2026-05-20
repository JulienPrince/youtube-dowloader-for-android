import 'package:flutter/material.dart';
import 'settings_service.dart';

/// État réactif du thème et de l'accent : un changement rebuild MaterialApp
/// (couleur/thème appliqués en live).
class SettingsController extends ChangeNotifier {
  final SettingsService _service;
  ThemeMode _themeMode;
  Color _accent;

  SettingsController(this._service, this._themeMode, this._accent);

  ThemeMode get themeMode => _themeMode;
  Color get accent => _accent;

  static Future<SettingsController> load(SettingsService service) async {
    return SettingsController(
      service,
      await service.themeMode(),
      await service.accent(),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _service.setThemeMode(mode);
  }

  Future<void> setAccent(Color color) async {
    _accent = color;
    notifyListeners();
    await _service.setAccent(color);
  }
}
