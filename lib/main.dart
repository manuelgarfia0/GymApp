import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/di/dependency_injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _hideBottomNavigationBar();
  SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
    if (systemOverlaysAreVisible) {
      Future<void>.delayed(
        const Duration(seconds: 2),
        _hideBottomNavigationBar,
      );
    }
  });

  // Inicializar la inyección de dependencias
  DependencyInjection.initialize();

  runApp(const GymApp());
}

Future<void> _hideBottomNavigationBar() {
  return SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [SystemUiOverlay.top],
  );
}
