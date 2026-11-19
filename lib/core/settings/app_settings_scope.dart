import 'package:flutter/widgets.dart';
import '../di/core_dependencies.dart';
import 'app_settings.dart';
import 'app_settings_service.dart';

/// Expone de forma reactiva [AppSettingsService] al árbol de widgets.
class AppSettingsScope extends InheritedNotifier<AppSettingsService> {
  const AppSettingsScope({
    super.key,
    required AppSettingsService super.notifier,
    required super.child,
  });

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    return scope?.notifier?.settings ?? CoreDependencies.settingsService.settings;
  }
}
