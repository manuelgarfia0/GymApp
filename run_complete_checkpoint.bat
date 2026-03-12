@echo off
echo ========================================
echo CHECKPOINT COMPLETO - LOGIN DATA LOADING FIX
echo ========================================

echo.
echo 1. Verificando backend...
curl -s http://localhost:8080/api/health || echo Backend no disponible

echo.
echo 2. Ejecutando tests de validación...
flutter test test/integration/behavior_validation_test.dart

echo.
echo 3. Ejecutando tests unitarios...
flutter test test/features/

echo.
echo 4. Ejecutando tests de exploración del bug...
flutter test test/features/auth/data/repositories/auth_repository_bug_exploration_test.dart

echo.
echo 5. Ejecutando tests de preservación...
flutter test test/features/auth/data/repositories/auth_repository_preservation_test.dart

echo.
echo 6. Ejecutando tests de integración (requiere backend)...
flutter test test/integration/

echo.
echo ========================================
echo CHECKPOINT COMPLETADO
echo ========================================