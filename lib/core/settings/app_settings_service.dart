import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/weight_converter.dart';
import 'app_settings.dart';

/// Servicio reactivo encargado de leer, actualizar y persistir [AppSettings].
class AppSettingsService extends ChangeNotifier {
  static const String keyThemeMode = 'settings_theme_mode';
  static const String keyLanguageCode = 'settings_language_code';
  static const String keyWeightUnit = 'settings_weight_unit';
  static const String keyDefaultRestSeconds = 'settings_default_rest_seconds';
  static const String keyRestSoundEnabled = 'settings_rest_sound_enabled';
  static const String keyRestVibrationEnabled =
      'settings_rest_vibration_enabled';
  static const String keyRestNotificationEnabled =
      'settings_rest_notification_enabled';
  static const String keyKeepScreenOn = 'settings_keep_screen_on';
  static const String keyHapticOnSetComplete = 'settings_haptic_on_set_complete';

  AppSettings _settings;

  AppSettingsService({AppSettings initialSettings = const AppSettings()})
      : _settings = initialSettings;

  AppSettings get settings => _settings;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeRaw = prefs.getString(keyThemeMode);
      final langRaw = prefs.getString(keyLanguageCode);
      final unitRaw = prefs.getString(keyWeightUnit);
      final restRaw = prefs.getInt(keyDefaultRestSeconds);
      final soundRaw = prefs.getBool(keyRestSoundEnabled);
      final vibrationRaw = prefs.getBool(keyRestVibrationEnabled);
      final notifRaw = prefs.getBool(keyRestNotificationEnabled);
      final wakelockRaw = prefs.getBool(keyKeepScreenOn);
      final hapticRaw = prefs.getBool(keyHapticOnSetComplete);

      final clampedRest = restRaw != null ? restRaw.clamp(15, 600) : 90;

      _settings = AppSettings(
        themeMode: _parseThemeMode(themeRaw),
        languageCode: langRaw == 'en' ? 'en' : 'es',
        weightUnit: WeightUnit.fromCode(unitRaw),
        defaultRestSeconds: clampedRest,
        restSoundEnabled: soundRaw ?? true,
        restVibrationEnabled: vibrationRaw ?? true,
        restNotificationEnabled: notifRaw ?? true,
        keepScreenOn: wakelockRaw ?? false,
        hapticOnSetComplete: hapticRaw ?? true,
      );
      notifyListeners();
    } catch (_) {
      // En entornos sin almacenamiento disponible se mantienen los valores por defecto.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_settings.themeMode == mode) return;
    _settings = _settings.copyWith(themeMode: mode);
    notifyListeners();
    await _persistString(keyThemeMode, _serializeThemeMode(mode));
  }

  Future<void> setLanguageCode(String code) async {
    final normalized = code.trim().toLowerCase() == 'en' ? 'en' : 'es';
    if (_settings.languageCode == normalized) return;
    _settings = _settings.copyWith(languageCode: normalized);
    notifyListeners();
    await _persistString(keyLanguageCode, normalized);
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    if (_settings.weightUnit == unit) return;
    _settings = _settings.copyWith(weightUnit: unit);
    notifyListeners();
    await _persistString(keyWeightUnit, unit.code);
  }

  Future<void> setDefaultRestSeconds(int seconds) async {
    final clamped = seconds.clamp(15, 600);
    if (_settings.defaultRestSeconds == clamped) return;
    _settings = _settings.copyWith(defaultRestSeconds: clamped);
    notifyListeners();
    await _persistInt(keyDefaultRestSeconds, clamped);
  }

  Future<void> setRestSoundEnabled(bool enabled) async {
    if (_settings.restSoundEnabled == enabled) return;
    _settings = _settings.copyWith(restSoundEnabled: enabled);
    notifyListeners();
    await _persistBool(keyRestSoundEnabled, enabled);
  }

  Future<void> setRestVibrationEnabled(bool enabled) async {
    if (_settings.restVibrationEnabled == enabled) return;
    _settings = _settings.copyWith(restVibrationEnabled: enabled);
    notifyListeners();
    await _persistBool(keyRestVibrationEnabled, enabled);
  }

  Future<void> setRestNotificationEnabled(bool enabled) async {
    if (_settings.restNotificationEnabled == enabled) return;
    _settings = _settings.copyWith(restNotificationEnabled: enabled);
    notifyListeners();
    await _persistBool(keyRestNotificationEnabled, enabled);
  }

  Future<void> setKeepScreenOn(bool enabled) async {
    if (_settings.keepScreenOn == enabled) return;
    _settings = _settings.copyWith(keepScreenOn: enabled);
    notifyListeners();
    await _persistBool(keyKeepScreenOn, enabled);
  }

  Future<void> setHapticOnSetComplete(bool enabled) async {
    if (_settings.hapticOnSetComplete == enabled) return;
    _settings = _settings.copyWith(hapticOnSetComplete: enabled);
    notifyListeners();
    await _persistBool(keyHapticOnSetComplete, enabled);
  }

  void resetInMemory() {
    _settings = const AppSettings();
    notifyListeners();
  }

  ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  Future<void> _persistString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _persistInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }
}
