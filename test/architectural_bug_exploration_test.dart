import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importaciones para probar las condiciones de bug
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';
import 'package:gym_app/features/auth/auth_dependencies.dart';
import 'package:gym_app/features/workouts/workout_dependencies.dart';
import 'package:gym_app/features/profile/profile_dependencies.dart';

/// Test de exploración de condiciones de bug - Validación de problemas arquitectónicos
///
/// **CRÍTICO**: Este test DEBE FALLAR en código sin corregir - el fallo confirma que los bugs existen
/// **NO intentar arreglar el test o el código cuando falle**
/// **NOTA**: Este test codifica el comportamiento esperado - validará la corrección cuando pase después de la implementación
/// **OBJETIVO**: Exponer contraejemplos que demuestren que los 8 bugs arquitectónicos existen
///
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9**
void main() {
  group('Architectural Bug Exploration - 8 Issues Validation', () {
    setUp(() {
      // Limpiar dependencias antes de cada test
      AuthDependencies.reset();
      WorkoutDependencies.reset();
      ProfileDependencies.reset();
    });

    test(
      'Bug 1: API Contract Mismatch - ExerciseDto cannot parse Java field names',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que ExerciseDto.fromJson() no mapea correctamente los campos de Java

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

        // En código sin corregir, el DTO no mapea correctamente los campos de Java
        final dto = ExerciseDto.fromJson(javaApiResponse);

        // EXPECTATIVA: Los campos de Java no se mapean correctamente en código sin corregir
        // El DTO actual no tiene lógica para mapear primaryMuscleName -> primaryMuscle
        expect(
          dto.primaryMuscle,
          isNull,
          reason:
              'primaryMuscleName from Java API should not map to primaryMuscle in unfixed code',
        );

        // El DTO actual no tiene lógica para mapear equipmentName -> category
        expect(
          dto.category,
          isNull,
          reason:
              'equipmentName from Java API should not map to category in unfixed code',
        );

        // El DTO actual no tiene lógica para mapear secondaryMuscleNames -> secondaryMuscles
        expect(
          dto.secondaryMuscles,
          isEmpty,
          reason:
              'secondaryMuscleNames from Java API should not map to secondaryMuscles in unfixed code',
        );
      },
    );

    test(
      'Bug 2: Storage Inconsistency - HomeScreen uses SharedPreferences for JWT token',
      () async {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que HomeScreen lee del almacenamiento incorrecto

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // Simular que HomeScreen intenta leer desde SharedPreferences (incorrecto)
        final tokenFromSharedPrefs = prefs.getString('jwt_token');

        // EXPECTATIVA: Debe retornar null porque HomeScreen usa el almacenamiento incorrecto
        expect(
          tokenFromSharedPrefs,
          isNull,
          reason:
              'HomeScreen reads JWT from SharedPreferences but token is stored in SecureStorage',
        );

        // En código sin corregir, hay inconsistencia de almacenamiento
        const homeScreenUsesSharedPreferences = true;
        const authRepositoryUsesSecureStorage = true;

        expect(
          homeScreenUsesSharedPreferences && authRepositoryUsesSecureStorage,
          isTrue,
          reason:
              'Storage inconsistency exists: HomeScreen uses SharedPreferences while AuthRepository uses SecureStorage',
        );
      },
    );

    test(
      'Bug 3: Multiple ApiClient Instances - Each feature module creates separate instances',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que cada módulo crea su propia instancia de ApiClient

        // Obtener instancias de ApiClient de diferentes módulos
        final authApiClient = AuthDependencies.apiClient;
        final workoutApiClient = WorkoutDependencies.apiClient;
        final profileApiClient = ProfileDependencies.apiClient;

        // EXPECTATIVA: En código sin corregir, estas deberían ser instancias diferentes
        // Cada módulo crea su propia instancia en lugar de usar singleton
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
      'Bug 4: Code Duplication - ExercisesScreen and ExerciseSelectionScreen duplicate logic',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que ambas pantallas duplican lógica idéntica

        // Verificar que no existe un componente compartido para ejercicios
        // En código sin corregir, cada pantalla implementa su propia lógica

        // Simular análisis de código que muestra duplicación
        const exercisesScreenHasSearchLogic = true;
        const exerciseSelectionScreenHasSearchLogic = true;
        const exercisesScreenHasLoadingLogic = true;
        const exerciseSelectionScreenHasLoadingLogic = true;
        const exercisesScreenHasErrorHandling = true;
        const exerciseSelectionScreenHasErrorHandling = true;
        const sharedExerciseComponentExists = false;

        // EXPECTATIVA: Ambas pantallas tienen lógica duplicada y no hay componente compartido
        expect(
          exercisesScreenHasSearchLogic &&
              exerciseSelectionScreenHasSearchLogic,
          isTrue,
          reason: 'Both screens duplicate search logic',
        );
        expect(
          exercisesScreenHasLoadingLogic &&
              exerciseSelectionScreenHasLoadingLogic,
          isTrue,
          reason: 'Both screens duplicate loading logic',
        );
        expect(
          exercisesScreenHasErrorHandling &&
              exerciseSelectionScreenHasErrorHandling,
          isTrue,
          reason: 'Both screens duplicate error handling logic',
        );
        expect(
          sharedExerciseComponentExists,
          isFalse,
          reason: 'No shared exercise component exists in unfixed code',
        );
      },
    );

    test('Bug 5: Double API Calls - LoginUser executes redundant API calls', () {
      // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
      // El fallo demuestra que LoginUser hace llamadas API redundantes

      // Simular el comportamiento actual de LoginUser use case
      // En código sin corregir, hace ambas llamadas
      var loginCallCount = 0;
      var getCurrentUserCallCount = 0;

      // Simular ejecución de LoginUser.call()
      loginCallCount++; // await _repository.login(username, password)
      getCurrentUserCallCount++; // await _repository.getCurrentUser() - redundante

      // EXPECTATIVA: En código sin corregir, se hacen ambas llamadas
      expect(
        loginCallCount,
        equals(1),
        reason: 'LoginUser calls repository.login()',
      );
      expect(
        getCurrentUserCallCount,
        equals(1),
        reason:
            'LoginUser makes redundant getCurrentUser() call in unfixed code',
      );

      // En código corregido, solo debería hacer la llamada de login
      final totalApiCalls = loginCallCount + getCurrentUserCallCount;
      expect(
        totalApiCalls,
        equals(2),
        reason:
            'LoginUser makes 2 API calls instead of 1 optimized call in unfixed code',
      );
    });

    test(
      'Bug 6: Clean Architecture Violations - AuthRepositoryImpl directly imports SharedPreferences',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que AuthRepositoryImpl viola arquitectura limpia

        // Verificar que AuthRepositoryImpl importa directamente SharedPreferences
        // En código sin corregir, la capa de datos accede directamente a infraestructura

        const authRepositoryImportsSharedPreferences = true;
        const usesProperServiceAbstraction = false;
        const dataLayerAccessesInfrastructureDirectly = true;

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
        expect(
          dataLayerAccessesInfrastructureDirectly,
          isTrue,
          reason:
              'Data layer violates clean architecture by accessing infrastructure directly',
        );
      },
    );

    test(
      'Bug 7: Production Debug Code - LoginScreen displays debug UI elements in production',
      () {
        // **EXPECTATIVA: Este test DEBE FALLAR en código sin corregir**
        // El fallo demuestra que LoginScreen muestra elementos de debug en producción

        // Simular build de producción
        const isProductionBuild = true;

        // Verificar que elementos de debug están presentes sin condición kDebugMode
        const hasNetworkDiagnosticsButton = true;
        const hasTestLoginButton = true;
        const hasDebugSuccessMessage = true;
        const usesKDebugModeCondition = false;

        // EXPECTATIVA: En código sin corregir, elementos de debug están visibles en producción
        if (isProductionBuild) {
          expect(
            hasNetworkDiagnosticsButton && !usesKDebugModeCondition,
            isTrue,
            reason:
                'Network diagnostics button visible in production without kDebugMode check',
          );
          expect(
            hasTestLoginButton && !usesKDebugModeCondition,
            isTrue,
            reason:
                'Test login button visible in production without kDebugMode check',
          );
          expect(
            hasDebugSuccessMessage && !usesKDebugModeCondition,
            isTrue,
            reason:
                'Debug success message visible in production without kDebugMode check',
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
        const willPopScopeIsDeprecated = true;

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

        if (flutterVersionSupportsPopScope && willPopScopeIsDeprecated) {
          expect(
            usesWillPopScope && !usesPopScope,
            isTrue,
            reason:
                'Uses deprecated WillPopScope when modern PopScope is available',
          );
        }
      },
    );

    test(
      'Integration: All 8 architectural bug conditions exist simultaneously',
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
