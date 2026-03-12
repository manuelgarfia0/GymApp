import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';
import 'package:gym_app/features/profile/data/models/user_profile_dto.dart';
import 'package:gym_app/features/workouts/data/models/routine_dto.dart';
import 'package:gym_app/features/workouts/data/models/workout_dto.dart';

/// **Valida: Requisitos 2.1, 2.2, 2.3, 2.4, 2.5**
///
/// Tests de Exploración de Condición de Bug para Problemas de Sincronización Null Safety
///
/// CRÍTICO: Estos tests DEBEN FALLAR en el código actual para probar que el bug existe.
/// Los fallos demuestran que los DTOs no pueden manejar campos nulos del backend,
/// causando crashes de deserialización cuando la base de datos contiene valores nulos legítimos.
///
/// NO corregir el código cuando estos tests fallen - los fallos son el resultado esperado
/// que prueba que la condición del bug existe.
void main() {
  group('Exploración de Condición de Bug - Sincronización Null Safety', () {
    group('Manejo de campos nulos en ExerciseDto', () {
      test('debería manejar campo description nulo sin crash', () {
        // Simula respuesta JSON del backend Spring Boot con description nulo
        // Este caso ocurre cuando la base de datos PostgreSQL tiene description = NULL
        final jsonWithNullDescription = {
          'id': 1,
          'name': 'Push-up',
          'description': null, // Campo nulo que causa el crash
          'primaryMuscle': 'Chest',
          'equipment': 'Bodyweight',
          'secondaryMuscles': ['Triceps', 'Shoulders'],
        };

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        // El fallo demuestra que ExerciseDto.fromJson() no puede manejar description nulo
        expect(
          () {
            final dto = ExerciseDto.fromJson(jsonWithNullDescription);
            // Si llegamos aquí, el DTO debería manejar el campo nulo correctamente
            expect(dto.description, isNull);
            expect(dto.name, equals('Push-up'));
            expect(dto.id, equals(1));
          },
          returnsNormally,
          reason: 'ExerciseDto debería manejar description nulo sin crash',
        );
      });

      test('debería manejar múltiples campos nulos en ExerciseDto', () {
        // Caso extremo: múltiples campos opcionales nulos
        final jsonWithMultipleNulls = {
          'id': 2,
          'name': 'Squat',
          'description': null,
          'primaryMuscle': null, // Otro campo que podría ser nulo
          'equipment': 'Barbell',
          'secondaryMuscles': null,
        };

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        expect(
          () {
            final dto = ExerciseDto.fromJson(jsonWithMultipleNulls);
            expect(dto.name, equals('Squat'));
            expect(dto.description, isNull);
          },
          returnsNormally,
          reason: 'ExerciseDto debería manejar múltiples campos nulos',
        );
      });
    });

    group('Problemas de enmascaramiento con fallbacks en UserProfileDto', () {
      test('debería exponer valores nulos en lugar de enmascararlos con fallbacks', () {
        // Simula respuesta del backend donde campos requeridos son legítimamente nulos
        // Los fallbacks con ?? enmascaran estos valores nulos que deberían ser preservados
        final jsonWithLegitimateNulls = {
          'id':
              null, // ID nulo del backend - fallback ?? 0 enmascara el problema
          'username':
              null, // Username nulo - fallback ?? '' enmascara el problema
          'email': null, // Email nulo - fallback ?? '' enmascara el problema
          'premium':
              null, // Premium nulo - fallback ?? false enmascara el problema
          'languagePreference': null,
          'createdAt': null,
        };

        // EXPECTATIVA: Este test DEBE PASAR después de la corrección
        // Los valores nulos legítimos del backend ahora se preservan correctamente
        expect(
          () {
            final dto = UserProfileDto.fromJson(jsonWithLegitimateNulls);
            // El comportamiento correcto es preservar los nulos sin enmascarar
            expect(
              dto.id,
              isNull,
              reason: 'Debería preservar id nulo sin fallback',
            );
            expect(
              dto.username,
              isNull,
              reason: 'Debería preservar username nulo sin fallback',
            );
            expect(
              dto.email,
              isNull,
              reason: 'Debería preservar email nulo sin fallback',
            );
          },
          returnsNormally,
          reason:
              'Debería preservar valores nulos legítimos sin enmascarar con fallbacks',
        );
      });
    });

    group('Manejo de timestamps nulos en WorkoutDto/WorkoutSetDto', () {
      test('debería manejar startTime nulo en WorkoutDto', () {
        // Simula respuesta del backend donde startTime es nulo
        // Esto puede ocurrir con workouts incompletos o en draft
        final jsonWithNullStartTime = {
          'id': 1,
          'name': 'Morning Workout',
          'startTime': null, // Campo nulo que causa crash
          'endTime': null,
          'userId': 1,
          'routineId': null,
          'sets': [],
        };

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        // WorkoutDto.startTime está definido como String no anulable
        expect(
          () {
            final dto = WorkoutDto.fromJson(jsonWithNullStartTime);
            expect(dto.name, equals('Morning Workout'));
            expect(dto.startTime, isNull);
          },
          returnsNormally,
          reason: 'WorkoutDto debería manejar startTime nulo',
        );
      });

      test('debería manejar timestamp nulo en WorkoutSetDto', () {
        // Simula respuesta del backend donde timestamp es nulo
        // Esto puede ocurrir con sets no completados o en draft
        final jsonWithNullTimestamp = {
          'exerciseId': 1,
          'exerciseName': 'Bench Press',
          'exerciseOrder': 1,
          'setNumber': 1,
          'weight': 80.0,
          'reps': 10,
          'timestamp': null, // Campo nulo que causa crash
          'notes': null,
        };

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        // WorkoutSetDto.timestamp está definido como String no anulable
        expect(
          () {
            final dto = WorkoutSetDto.fromJson(jsonWithNullTimestamp);
            expect(dto.exerciseId, equals(1));
            expect(dto.timestamp, isNull);
          },
          returnsNormally,
          reason: 'WorkoutSetDto debería manejar timestamp nulo',
        );
      });

      test('debería manejar createdAt nulo en RoutineDto', () {
        // Simula respuesta del backend donde createdAt es nulo
        final jsonWithNullCreatedAt = {
          'id': 1,
          'name': 'Push Day',
          'description': null, // También probamos description nulo
          'userId': 1,
          'exercises': [],
          'createdAt': null,
        };

        // EXPECTATIVA: Este test podría pasar ya que createdAt es String? en RoutineDto
        // Pero description podría causar problemas si no es nullable
        expect(
          () {
            final dto = RoutineDto.fromJson(jsonWithNullCreatedAt);
            expect(dto.name, equals('Push Day'));
            expect(dto.createdAt, isNull);
            expect(
              dto.description,
              isNull,
            ); // Esto podría fallar si description no es nullable
          },
          returnsNormally,
          reason: 'RoutineDto debería manejar campos nulos',
        );
      });
    });

    group('Escenarios de integración - Múltiples DTOs con campos nulos', () {
      test(
        'debería manejar perfil de usuario completo con descripciones de ejercicios nulas',
        () {
          // Escenario de integración: usuario con perfil parcial y ejercicios con descripciones nulas
          final userProfileJson = {
            'id': null,
            'username': 'testuser',
            'email': null,
            'premium': null,
            'languagePreference': null,
            'createdAt': null,
          };

          final exerciseJson = {
            'id': 1,
            'name': 'Custom Exercise',
            'description': null,
            'primaryMuscle': 'Unknown',
            'equipment': 'None',
            'secondaryMuscles': [],
          };

          // EXPECTATIVA: Ambos DTOs DEBEN FALLAR en código sin corregir
          expect(
            () {
              final userProfile = UserProfileDto.fromJson(userProfileJson);
              final exercise = ExerciseDto.fromJson(exerciseJson);

              // Si llegamos aquí, ambos DTOs manejan correctamente los campos nulos
              expect(userProfile.username, equals('testuser'));
              expect(exercise.name, equals('Custom Exercise'));
              expect(exercise.description, isNull);
            },
            returnsNormally,
            reason:
                'Ambos DTOs deberían manejar campos nulos en escenario de integración',
          );
        },
      );
    });
  });
}
