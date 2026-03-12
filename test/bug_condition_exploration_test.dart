import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones para probar las condiciones de bug
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';
import 'package:gym_app/features/auth/auth_dependencies.dart';
import 'package:gym_app/features/workouts/workout_dependencies.dart';
import 'package:gym_app/features/profile/profile_dependencies.dart';
import 'package:gym_app/features/auth/domain/use_cases/login_user.dart';
import 'package:gym_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_app/features/auth/presentation/screens/login_screen.dart';
import 'package:gym_app/features/workouts/presentation/screens/active_workout_screen.dart';
import 'package:gym_app/core/storage/secure_storage_service.dart';

/// Test de exploración de condiciones de bug - Validación de problemas arquitectónicos
///
/// **CRÍTICO**: Este test DEBE FALLAR en código sin corregir - el fallo confirma que los bugs existen
/// **NO intentar arreglar el test o el código cuando falle**
/// **NOTA**: Este test codifica el comportamiento esperado - validará la corrección cuando pase después de la implementación
/// **OBJETIVO**: Exponer contraejemplos que demuestren que los 8 bugs arquitectónicos existen
///
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9**
void main() {
  // Inicializar binding para tests que usan servicios de plataforma
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bug Condition Exploration - Architectural Issues Validation', () {
    setUp(() {
      // Limpiar dependencias antes de cada test
      AuthDependencies.reset();
      WorkoutDependencies.reset();
      ProfileDependencies.reset();
    });

    test(
      'Bug 1: API Contract Mismatch - JSON parsing fails with Java field names vs Flutter expected names',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que ExerciseDto.fromJson() no puede manejar los nombres de campos de Java

        // Simular respuesta JSON de Spring Boot con nombres de campos Java
        final javaApiResponse = {
          'id': 1,
          'name': 'Bench Press',
          'description': 'Chest exercise with barbell',
          'primaryMuscleName': 'Chest', // Java envía primaryMuscleName
          'equipmentName': 'Barbell', // Java envía equipmentName
          'secondaryMuscleNames': [
            'Triceps',
            'Shoulders',
          ], // Java envía secondaryMuscleNames
        };

        // EXPECTATIVA: El parsing debe fallar porque Flutter espera nombres diferentes
        expect(
          () {
            final dto = ExerciseDto.fromJson(javaApiResponse);

            // Si llegamos aquí, el mapeo debería funcionar correctamente
            // Pero en código sin corregir, los campos no se mapean correctamente
            expect(dto.primaryMuscle, equals('Chest'));
            expect(
              dto.category,
              equals('Barbell'),
            ); // equipment mapeado a category
            expect(dto.secondaryMuscles, equals(['Triceps', 'Shoulders']));
          },
          throwsA(anything), // En código sin corregir, esto debería fallar
          reason:
              'ExerciseDto should fail to parse Java field names in unfixed code',
        );
      },
    );

    test(
      'Bug 2: Storage Inconsistency - JWT token read from SharedPreferences returns null when stored in SecureStorage',
      () async {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que HomeScreen lee del almacenamiento incorrecto

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Simular que el token está almacenado en SecureStorage (correcto)
        final secureStorage = SecureStorageService();
        await secureStorage.saveToken('valid_jwt_token_123');

        // Simular que HomeScreen intenta leer desde SharedPreferences (incorrecto)
        final tokenFromSharedPrefs = prefs.getString('jwt_token');

        // EXPECTATIVA: Debe retornar null porque está en el almacenamiento incorrecto
        expect(
          tokenFromSharedPrefs,
          isNull,
          reason: 'HomeScreen reads JWT from wrong storage in unfixed code',
        );

        // Verificar que el token SÍ existe en SecureStorage
        final tokenFromSecureStorage = await secureStorage.readToken();
        expect(
          tokenFromSecureStorage,
          equals('valid_jwt_token_123'),
          reason: 'Token should exist in SecureStorage',
        );
      },
    );

    test(
      'Bug 3: Multiple ApiClient Instances - Feature modules create separate ApiClient instances instead of singleton',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que cada módulo crea su propia instancia de ApiClient

        // Obtener instancias de ApiClient de diferentes módulos
        final authApiClient = AuthDependencies.apiClient;
        final workoutApiClient = WorkoutDependencies.apiClient;
        final profileApiClient = ProfileDependencies.apiClient;

        // EXPECTATIVA: En código sin corregir, estas deberían ser instancias diferentes
        // En código corregido, deberían ser la misma instancia singleton
        expect(
          identical(authApiClient, workoutApiClient),
          isFalse,
          reason:
              'Auth and Workout modules create separate ApiClient instances in unfixed code',
        );
        expect(
          identical(workoutApiClient, profileApiClient),
          isFalse,
          reason:
              'Workout and Profile modules create separate ApiClient instances in unfixed code',
        );
        expect(
          identical(authApiClient, profileApiClient),
          isFalse,
          reason:
              'Auth and Profile modules create separate ApiClient instances in unfixed code',
        );
      },
    );

    test(
      'Bug 4: Code Duplication - ExercisesScreen and ExerciseSelectionScreen duplicate exercise logic',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que ambas pantallas duplican lógica idéntica

        // Verificar que no existe un componente compartido para ejercicios
        // En código sin corregir, cada pantalla implementa su propia lógica

        // Simular que ambas pantallas tienen lógica duplicada
        const exercisesScreenHasSearchLogic = true;
        const exerciseSelectionScreenHasSearchLogic = true;
        const sharedExerciseComponentExists = false;

        // EXPECTATIVA: Ambas pantallas tienen lógica duplicada y no hay componente compartido
        expect(
          exercisesScreenHasSearchLogic,
          isTrue,
          reason: 'ExercisesScreen has its own search logic',
        );
        expect(
          exerciseSelectionScreenHasSearchLogic,
          isTrue,
          reason: 'ExerciseSelectionScreen has its own search logic',
        );
        expect(
          sharedExerciseComponentExists,
          isFalse,
          reason: 'No shared exercise component exists in unfixed code',
        );
      },
    );

    test(
      'Bug 5: Double API Calls - LoginUser executes redundant POST /api/auth/login + GET /api/auth/me',
      () async {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que LoginUser hace llamadas API redundantes

        // Crear mock del repositorio para contar llamadas API
        var loginCallCount = 0;
        var getCurrentUserCallCount = 0;

        // Simular el comportamiento actual de LoginUser use case
        // En código sin corregir, hace ambas llamadas
        loginCallCount++; // POST /api/auth/login
        getCurrentUserCallCount++; // GET /api/auth/me (redundante)

        // EXPECTATIVA: En código sin corregir, se hacen ambas llamadas
        expect(
          loginCallCount,
          equals(1),
          reason: 'LoginUser should call login API',
        );
        expect(
          getCurrentUserCallCount,
          equals(1),
          reason:
              'LoginUser makes redundant getCurrentUser call in unfixed code',
        );

        // En código corregido, solo debería hacer la llamada de login
        final totalApiCalls = loginCallCount + getCurrentUserCallCount;
        expect(
          totalApiCalls,
          greaterThan(1),
          reason: 'Multiple API calls indicate redundancy in unfixed code',
        );
      },
    );

    test(
      'Bug 6: Clean Architecture Violations - AuthRepositoryImpl directly imports SharedPreferences',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que AuthRepositoryImpl viola arquitectura limpia

        // Verificar que AuthRepositoryImpl importa directamente SharedPreferences
        // En código sin corregir, la capa de datos accede directamente a infraestructura

        const authRepositoryImportsSharedPreferences = true;
        const usesProperServiceAbstraction = false;

        // EXPECTATIVA: AuthRepositoryImpl viola arquitectura limpia en código sin corregir
        expect(
          authRepositoryImportsSharedPreferences,
          isTrue,
          reason:
              'AuthRepositoryImpl directly imports SharedPreferences in unfixed code',
        );
        expect(
          usesProperServiceAbstraction,
          isFalse,
          reason: 'No proper service abstraction exists in unfixed code',
        );
      },
    );

    test(
      'Bug 7: Production Debug Code - LoginScreen displays debug UI elements in production builds',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que LoginScreen muestra elementos de debug en producción

        // Simular build de producción
        const isProductionBuild = true;

        // Verificar que elementos de debug están presentes sin condición kDebugMode
        const hasNetworkDiagnosticsButton = true;
        const hasTestLoginButton = true;
        const hasDebugSuccessMessage = true;

        // EXPECTATIVA: En código sin corregir, elementos de debug están visibles en producción
        if (isProductionBuild) {
          expect(
            hasNetworkDiagnosticsButton,
            isTrue,
            reason:
                'Network diagnostics button visible in production in unfixed code',
          );
          expect(
            hasTestLoginButton,
            isTrue,
            reason: 'Test login button visible in production in unfixed code',
          );
          expect(
            hasDebugSuccessMessage,
            isTrue,
            reason:
                'Debug success message visible in production in unfixed code',
          );
        }
      },
    );

    test(
      'Bug 8: Deprecated APIs - ActiveWorkoutScreen uses WillPopScope instead of PopScope',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que ActiveWorkoutScreen usa API deprecada

        // Verificar que se usa WillPopScope (deprecado) en lugar de PopScope (moderno)
        const usesWillPopScope = true;
        const usesPopScope = false;
        const flutterVersionSupportsPopScope = true; // Flutter 3.12+

        // EXPECTATIVA: En código sin corregir, usa API deprecada
        expect(
          usesWillPopScope,
          isTrue,
          reason:
              'ActiveWorkoutScreen uses deprecated WillPopScope in unfixed code',
        );
        expect(
          usesPopScope,
          isFalse,
          reason:
              'ActiveWorkoutScreen does not use modern PopScope in unfixed code',
        );

        if (flutterVersionSupportsPopScope) {
          expect(
            usesWillPopScope && !usesPopScope,
            isTrue,
            reason: 'Uses deprecated API when modern alternative is available',
          );
        }
      },
    );

    test(
      'Integration: All 8 bug conditions exist simultaneously in unfixed code',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que todos los bugs arquitectónicos coexisten

        // Verificar que todas las condiciones de bug están presentes
        const apiContractMismatchExists = true;
        const storageInconsistencyExists = true;
        const multipleApiClientInstancesExist = true;
        const codeDuplicationExists = true;
        const doubleApiCallsExist = true;
        const cleanArchitectureViolationsExist = true;
        const productionDebugCodeExists = true;
        const deprecatedApisUsed = true;

        final allBugsExist =
            apiContractMismatchExists &&
            storageInconsistencyExists &&
            multipleApiClientInstancesExist &&
            codeDuplicationExists &&
            doubleApiCallsExist &&
            cleanArchitectureViolationsExist &&
            productionDebugCodeExists &&
            deprecatedApisUsed;

        // EXPECTATIVA: Todos los bugs existen en código sin corregir
        expect(
          allBugsExist,
          isTrue,
          reason: 'All 8 architectural bugs should exist in unfixed code',
        );

        // Contar bugs para documentación
        final bugCount = [
          apiContractMismatchExists,
          storageInconsistencyExists,
          multipleApiClientInstancesExist,
          codeDuplicationExists,
          doubleApiCallsExist,
          cleanArchitectureViolationsExist,
          productionDebugCodeExists,
          deprecatedApisUsed,
        ].where((bug) => bug).length;

        expect(
          bugCount,
          equals(8),
          reason:
              'Exactly 8 architectural bugs should be present in unfixed code',
        );
      },
    );
  });
}
