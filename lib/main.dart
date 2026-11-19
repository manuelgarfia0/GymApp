import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/di/core_dependencies.dart';
import 'core/di/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES');
  await initializeDateFormatting('en_GB');
  _hideBottomNavigationBar();
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (systemOverlaysAreVisible) {
      Future<void>.delayed(
        const Duration(seconds: 2),
        _hideBottomNavigationBar,
      );
    }
  });

  // Inicializar la inyección de dependencias y cargar preferencias locales
  DependencyInjection.initialize();
  await CoreDependencies.settingsService.load();

  runApp(const GymApp());
}

Future<void> _hideBottomNavigationBar() {
  return SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top],
  );
}
