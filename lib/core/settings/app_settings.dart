import 'package:flutter/material.dart';
import '../utils/weight_converter.dart';

/// Modelo inmutable con las preferencias globales persistidas localmente.
class AppSettings {
  final ThemeMode themeMode;
  final String languageCode;
  final WeightUnit weightUnit;
  final int defaultRestSeconds;
  final bool restSoundEnabled;
  final bool restVibrationEnabled;
  final bool restNotificationEnabled;
  final bool keepScreenOn;
  final bool hapticOnSetComplete;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.languageCode = 'es',
    this.weightUnit = WeightUnit.kg,
    this.defaultRestSeconds = 90,
    this.restSoundEnabled = true,
    this.restVibrationEnabled = true,
    this.restNotificationEnabled = true,
    this.keepScreenOn = false,
    this.hapticOnSetComplete = true,
  });

  /// Locale activo de MaterialApp manteniendo lunes como primer día en calendarios.
  Locale get locale =>
      languageCode == 'en' ? const Locale('en', 'GB') : const Locale('es', 'ES');

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    WeightUnit? weightUnit,
    int? defaultRestSeconds,
    bool? restSoundEnabled,
    bool? restVibrationEnabled,
    bool? restNotificationEnabled,
    bool? keepScreenOn,
    bool? hapticOnSetComplete,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      weightUnit: weightUnit ?? this.weightUnit,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      restSoundEnabled: restSoundEnabled ?? this.restSoundEnabled,
      restVibrationEnabled: restVibrationEnabled ?? this.restVibrationEnabled,
      restNotificationEnabled:
          restNotificationEnabled ?? this.restNotificationEnabled,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      hapticOnSetComplete: hapticOnSetComplete ?? this.hapticOnSetComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.languageCode == languageCode &&
        other.weightUnit == weightUnit &&
        other.defaultRestSeconds == defaultRestSeconds &&
        other.restSoundEnabled == restSoundEnabled &&
        other.restVibrationEnabled == restVibrationEnabled &&
        other.restNotificationEnabled == restNotificationEnabled &&
        other.keepScreenOn == keepScreenOn &&
        other.hapticOnSetComplete == hapticOnSetComplete;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        languageCode,
        weightUnit,
        defaultRestSeconds,
        restSoundEnabled,
        restVibrationEnabled,
        restNotificationEnabled,
        keepScreenOn,
        hapticOnSetComplete,
      );
}
