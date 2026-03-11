import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/dependency_injection.dart';

void main() {
  // Inicializar la inyección de dependencias
  DependencyInjection.initialize();

  runApp(const GymApp());
}
