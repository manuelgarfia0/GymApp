import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/core/settings/app_settings_service.dart';
import 'package:gym_app/core/utils/weight_converter.dart';

void main() {
  group('AppSettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads default values when preferences are empty', () async {
      final service = AppSettingsService();
      await service.load();

      expect(service.settings.themeMode, ThemeMode.dark);
      expect(service.settings.languageCode, 'es');
      expect(service.settings.weightUnit, WeightUnit.kg);
      expect(service.settings.defaultRestSeconds, 90);
      expect(service.settings.restSoundEnabled, isTrue);
      expect(service.settings.restVibrationEnabled, isTrue);
      expect(service.settings.restNotificationEnabled, isTrue);
      expect(service.settings.keepScreenOn, isFalse);
      expect(service.settings.hapticOnSetComplete, isTrue);
    });

    test('persists and reloads all settings across instances', () async {
      final service = AppSettingsService();
      var notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setThemeMode(ThemeMode.light);
      await service.setLanguageCode('EN');
      await service.setWeightUnit(WeightUnit.lb);
      await service.setDefaultRestSeconds(120);
      await service.setRestSoundEnabled(false);
      await service.setRestVibrationEnabled(false);
      await service.setRestNotificationEnabled(false);
      await service.setKeepScreenOn(true);
      await service.setHapticOnSetComplete(false);

      expect(notifyCount, 9);

      final reloaded = AppSettingsService();
      await reloaded.load();

      expect(reloaded.settings.themeMode, ThemeMode.light);
      expect(reloaded.settings.languageCode, 'en');
      expect(reloaded.settings.locale, const Locale('en', 'GB'));
      expect(reloaded.settings.weightUnit, WeightUnit.lb);
      expect(reloaded.settings.defaultRestSeconds, 120);
      expect(reloaded.settings.restSoundEnabled, isFalse);
      expect(reloaded.settings.restVibrationEnabled, isFalse);
      expect(reloaded.settings.restNotificationEnabled, isFalse);
      expect(reloaded.settings.keepScreenOn, isTrue);
      expect(reloaded.settings.hapticOnSetComplete, isFalse);
    });

    test('clamps defaultRestSeconds between 15 and 600 on load', () async {
      SharedPreferences.setMockInitialValues({
        AppSettingsService.keyDefaultRestSeconds: 9999,
      });
      final service = AppSettingsService();
      await service.load();

      expect(service.settings.defaultRestSeconds, 600);
    });
  });
}
