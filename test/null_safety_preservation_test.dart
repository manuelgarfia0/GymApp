import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/models/user_dto.dart';
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';
import 'package:gym_app/features/profile/data/models/user_profile_dto.dart';
import 'package:gym_app/features/workouts/data/models/routine_dto.dart';
import 'package:gym_app/features/workouts/data/models/workout_dto.dart';

/// **Valida: Requisitos 3.1, 3.2, 3.3, 3.4, 3.5**
///
/// Tests de Preservación de Propiedades para Sincronización Null Safety
///
/// CRÍTICO: Estos tests DEBEN PASAR en el código actual para establecer el comportamiento baseline.
/// Capturan el comportamiento existente de deserialización con datos completos que debe preservarse
/// después de la corrección del bug.
///
/// Metodología observation-first: Observar comportamiento actual en código SIN CORREGIR
/// para entradas no buggy, luego escribir property-based tests capturando estos patrones.
void main() {
  group('Preservación de Propiedades - Comportamiento con Datos Completos', () {
    group('UserDto - Preservación de deserialización completa', () {
      test(
        'debería preservar deserialización exitosa con todos los campos poblados',
        () {
          // Datos completos típicos del backend - sin campos nulos
          final completeUserJson = {
            'id': 1,
            'username': 'manuel_garcia',
            'email': 'manuel@example.com',
            'isPremium': true,
            'languagePreference': 'es',
            'createdAt': '2024-01-15T10:30:00Z',
            'publicProfile': true,
          };

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Establece el comportamiento baseline que debe preservarse
          final dto = UserDto.fromJson(completeUserJson);

          expect(dto.id, equals(1));
          expect(dto.username, equals('manuel_garcia'));
          expect(dto.email, equals('manuel@example.com'));
          expect(dto.isPremium, equals(true));
          expect(dto.languagePreference, equals('es'));
          expect(dto.createdAt, equals('2024-01-15T10:30:00Z'));
          expect(dto.publicProfile, equals(true));
        },
      );

      test('debería preservar conversión DTO->Entity con datos completos', () {
        final completeUserJson = {
          'id': 2,
          'username': 'test_user',
          'email': 'test@example.com',
          'isPremium': false,
          'languagePreference': 'en',
          'createdAt': '2024-02-20T14:45:00Z',
          'publicProfile': false,
        };

        final dto = UserDto.fromJson(completeUserJson);
        final entity = dto.toEntity();

        // Verificar que la conversión a entity preserva todos los datos
        expect(entity.id, equals(2));
        expect(entity.username, equals('test_user'));
        expect(entity.email, equals('test@example.com'));
        expect(entity.isPremium, equals(false));
        expect(entity.languagePreference, equals('en'));
        expect(entity.createdAt, isNotNull);
        expect(entity.createdAt!.year, equals(2024));
        expect(entity.createdAt!.month, equals(2));
        expect(entity.createdAt!.day, equals(20));
      });

      test('debería preservar serialización DTO->JSON con datos completos', () {
        final dto = UserDto(
          id: 3,
          username: 'serialization_test',
          email: 'serial@example.com',
          isPremium: true,
          languagePreference: 'es',
          createdAt: '2024-03-10T09:15:00Z',
          publicProfile: true,
        );

        final json = dto.toJson();

        // Verificar que la serialización preserva todos los campos
        expect(json['id'], equals(3));
        expect(json['username'], equals('serialization_test'));
        expect(json['email'], equals('serial@example.com'));
        expect(json['isPremium'], equals(true));
        expect(json['languagePreference'], equals('es'));
        expect(json['createdAt'], equals('2024-03-10T09:15:00Z'));
        expect(json['publicProfile'], equals(true));
      });
    });

    group('ExerciseDto - Preservación de deserialización completa', () {
      test(
        'debería preservar deserialización exitosa con todos los campos poblados',
        () {
          // Datos completos típicos del backend - sin campos nulos
          final completeExerciseJson = {
            'id': 1,
            'name': 'Bench Press',
            'description': 'Compound chest exercise performed lying on a bench',
            'primaryMuscle': 'Chest',
            'category': 'Barbell',
            'secondaryMuscles': ['Triceps', 'Shoulders'],
          };

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          final dto = ExerciseDto.fromJson(completeExerciseJson);

          expect(dto.id, equals(1));
          expect(dto.name, equals('Bench Press'));
          expect(
            dto.description,
            equals('Compound chest exercise performed lying on a bench'),
          );
          expect(dto.primaryMuscle, equals('Chest'));
          expect(dto.category, equals('Barbell'));
          expect(dto.secondaryMuscles, equals(['Triceps', 'Shoulders']));
        },
      );

      test('debería preservar conversión DTO->Entity con datos completos', () {
        final completeExerciseJson = {
          'id': 2,
          'name': 'Squat',
          'description': 'Compound leg exercise',
          'primaryMuscle': 'Quadriceps',
          'category': 'Barbell',
          'secondaryMuscles': ['Glutes', 'Hamstrings'],
        };

        final dto = ExerciseDto.fromJson(completeExerciseJson);
        final entity = dto.toEntity();

        // Verificar que la conversión preserva todos los datos
        expect(entity.id, equals(2));
        expect(entity.name, equals('Squat'));
        expect(entity.description, equals('Compound leg exercise'));
        expect(entity.primaryMuscle, equals('Quadriceps'));
        expect(entity.category, equals('Barbell'));
        expect(entity.secondaryMuscles, equals(['Glutes', 'Hamstrings']));
      });
    });

    group('RoutineDto - Preservación de deserialización completa', () {
      test(
        'debería preservar deserialización exitosa con todos los campos poblados',
        () {
          final completeRoutineJson = {
            'id': 1,
            'name': 'Push Day',
            'description': 'Upper body pushing exercises',
            'userId': 1,
            'exercises': [
              {
                'id': 1,
                'exerciseId': 1,
                'exerciseName': 'Bench Press',
                'orderIndex': 0,
                'sets': 3,
                'reps': 10,
                'restSeconds': 120,
                'notes': 'Focus on form',
              },
            ],
            'createdAt': '2024-01-15T10:30:00Z',
          };

          final dto = RoutineDto.fromJson(completeRoutineJson);

          expect(dto.id, equals(1));
          expect(dto.name, equals('Push Day'));
          expect(dto.description, equals('Upper body pushing exercises'));
          expect(dto.userId, equals(1));
          expect(dto.exercises.length, equals(1));
          expect(dto.exercises[0].exerciseName, equals('Bench Press'));
          expect(dto.createdAt, equals('2024-01-15T10:30:00Z'));
        },
      );

      test('debería preservar conversión DTO->Entity con datos completos', () {
        final completeRoutineJson = {
          'id': 2,
          'name': 'Pull Day',
          'description': 'Upper body pulling exercises',
          'userId': 2,
          'exercises': [],
          'createdAt': '2024-02-20T14:45:00Z',
        };

        final dto = RoutineDto.fromJson(completeRoutineJson);
        final entity = dto.toEntity();

        expect(entity.id, equals(2));
        expect(entity.name, equals('Pull Day'));
        expect(entity.description, equals('Upper body pulling exercises'));
        expect(entity.userId, equals(2));
        expect(entity.exercises, isEmpty);
        expect(entity.createdAt, isNotNull);
        expect(entity.createdAt!.year, equals(2024));
      });
    });

    group('WorkoutDto - Preservación de deserialización completa', () {
      test(
        'debería preservar deserialización exitosa con todos los campos poblados',
        () {
          final completeWorkoutJson = {
            'id': 1,
            'name': 'Morning Workout',
            'startTime': '2024-01-15T08:00:00Z',
            'endTime': '2024-01-15T09:30:00Z',
            'userId': 1,
            'routineId': 1,
            'sets': [
              {
                'exerciseId': 1,
                'exerciseName': 'Bench Press',
                'exerciseOrder': 1,
                'setNumber': 1,
                'weight': 80.0,
                'reps': 10,
                'timestamp': '2024-01-15T08:15:00Z',
                'notes': 'Good form',
              },
            ],
          };

          final dto = WorkoutDto.fromJson(completeWorkoutJson);

          expect(dto.id, equals(1));
          expect(dto.name, equals('Morning Workout'));
          expect(dto.startTime, equals('2024-01-15T08:00:00Z'));
          expect(dto.endTime, equals('2024-01-15T09:30:00Z'));
          expect(dto.userId, equals(1));
          expect(dto.routineId, equals(1));
          expect(dto.sets.length, equals(1));
          expect(dto.sets[0].weight, equals(80.0));
        },
      );

      test('debería preservar conversión DTO->Entity con datos completos', () {
        final completeWorkoutJson = {
          'id': 2,
          'name': 'Evening Workout',
          'startTime': '2024-02-20T18:00:00Z',
          'endTime': '2024-02-20T19:15:00Z',
          'userId': 2,
          'routineId': null,
          'sets': [],
        };

        final dto = WorkoutDto.fromJson(completeWorkoutJson);
        final entity = dto.toEntity();

        expect(entity.id, equals(2));
        expect(entity.name, equals('Evening Workout'));
        expect(entity.startTime.year, equals(2024));
        expect(entity.endTime, isNotNull);
        expect(entity.endTime!.hour, equals(19));
        expect(entity.userId, equals(2));
        expect(entity.routineId, isNull);
        expect(entity.sets, isEmpty);
      });
    });

    group('UserProfileDto - Preservación de deserialización completa', () {
      test(
        'debería preservar deserialización exitosa con todos los campos poblados',
        () {
          final completeProfileJson = {
            'id': 1,
            'username': 'complete_user',
            'email': 'complete@example.com',
            'isPremium': true,
            'languagePreference': 'es',
            'createdAt': '2024-01-15T10:30:00Z',
            'firstName': 'Manuel',
            'lastName': 'García',
            'dateOfBirth': '1990-05-15',
            'preferences': {
              'theme': 'dark',
              'notifications': true,
              'units': 'metric',
            },
          };

          final dto = UserProfileDto.fromJson(completeProfileJson);

          expect(dto.id, equals(1));
          expect(dto.username, equals('complete_user'));
          expect(dto.email, equals('complete@example.com'));
          expect(dto.isPremium, equals(true));
          expect(dto.languagePreference, equals('es'));
          expect(dto.createdAt, equals('2024-01-15T10:30:00Z'));
          expect(dto.firstName, equals('Manuel'));
          expect(dto.lastName, equals('García'));
          expect(dto.dateOfBirth, equals('1990-05-15'));
          expect(dto.preferences, isNotNull);
          expect(dto.preferences!['theme'], equals('dark'));
        },
      );

      test('debería preservar conversión DTO->Entity con datos completos', () {
        final completeProfileJson = {
          'id': 2,
          'username': 'entity_test',
          'email': 'entity@example.com',
          'isPremium': false,
          'languagePreference': 'en',
          'createdAt': '2024-02-20T14:45:00Z',
          'firstName': 'Test',
          'lastName': 'User',
          'dateOfBirth': '1985-12-25',
          'preferences': {'units': 'imperial'},
        };

        final dto = UserProfileDto.fromJson(completeProfileJson);
        final entity = dto.toEntity();

        expect(entity.userId, equals(2));
        expect(entity.username, equals('entity_test'));
        expect(entity.email, equals('entity@example.com'));
        expect(entity.isPremium, equals(false));
        expect(entity.languagePreference, equals('en'));
        expect(entity.createdAt, isNotNull);
        expect(entity.firstName, equals('Test'));
        expect(entity.lastName, equals('User'));
        expect(entity.dateOfBirth, isNotNull);
        expect(entity.dateOfBirth!.year, equals(1985));
        expect(entity.preferences['units'], equals('imperial'));
      });
    });

    group('Property-Based Testing - Preservación de comportamiento', () {
      test(
        'debería preservar comportamiento de UserDto para múltiples configuraciones válidas',
        () {
          // Generar múltiples configuraciones de datos completos válidos
          final testCases = [
            {
              'id': 1,
              'username': 'user1',
              'email': 'user1@test.com',
              'isPremium': true,
              'languagePreference': 'es',
              'createdAt': '2024-01-01T00:00:00Z',
              'publicProfile': true,
            },
            {
              'id': 2,
              'username': 'user2',
              'email': 'user2@test.com',
              'isPremium': false,
              'languagePreference': 'en',
              'createdAt': '2024-06-15T12:30:00Z',
              'publicProfile': false,
            },
            {
              'id': 999,
              'username': 'max_user',
              'email': 'max@test.com',
              'isPremium': true,
              'languagePreference': 'fr',
              'createdAt': '2024-12-31T23:59:59Z',
              'publicProfile': true,
            },
          ];

          for (final testCase in testCases) {
            final dto = UserDto.fromJson(testCase);
            final entity = dto.toEntity();
            final backToJson = dto.toJson();

            // Verificar que el ciclo completo preserva los datos
            expect(dto.id, equals(testCase['id']));
            expect(dto.username, equals(testCase['username']));
            expect(dto.email, equals(testCase['email']));
            expect(entity.id, equals(testCase['id']));
            expect(backToJson['id'], equals(testCase['id']));
            expect(backToJson['username'], equals(testCase['username']));
          }
        },
      );

      test(
        'debería preservar comportamiento de ExerciseDto para múltiples configuraciones válidas',
        () {
          final testCases = [
            {
              'id': 1,
              'name': 'Push-up',
              'description': 'Bodyweight chest exercise',
              'primaryMuscle': 'Chest',
              'category': 'Bodyweight',
              'secondaryMuscles': ['Triceps'],
            },
            {
              'id': 2,
              'name': 'Deadlift',
              'description': 'Compound full-body exercise',
              'primaryMuscle': 'Hamstrings',
              'category': 'Barbell',
              'secondaryMuscles': ['Glutes', 'Lower Back', 'Traps'],
            },
            {
              'id': 3,
              'name': 'Plank',
              'description': 'Core stability exercise',
              'primaryMuscle': 'Core',
              'category': 'Bodyweight',
              'secondaryMuscles': [],
            },
          ];

          for (final testCase in testCases) {
            final dto = ExerciseDto.fromJson(testCase);
            final entity = dto.toEntity();
            final backToJson = dto.toJson();

            // Verificar que el ciclo completo preserva los datos
            expect(dto.id, equals(testCase['id']));
            expect(dto.name, equals(testCase['name']));
            expect(dto.description, equals(testCase['description']));
            expect(entity.id, equals(testCase['id']));
            expect(entity.name, equals(testCase['name']));
            expect(backToJson['id'], equals(testCase['id']));
            expect(backToJson['name'], equals(testCase['name']));
            expect(backToJson['description'], equals(testCase['description']));
          }
        },
      );

      test(
        'debería preservar comportamiento de WorkoutDto para múltiples configuraciones válidas',
        () {
          final testCases = [
            {
              'id': 1,
              'name': 'Quick Workout',
              'startTime': '2024-01-15T08:00:00Z',
              'endTime': '2024-01-15T08:30:00Z',
              'userId': 1,
              'routineId': 1,
              'sets': [],
            },
            {
              'id': 2,
              'name': 'Long Session',
              'startTime': '2024-02-20T18:00:00Z',
              'endTime': '2024-02-20T20:00:00Z',
              'userId': 2,
              'routineId': null,
              'sets': [],
            },
          ];

          for (final testCase in testCases) {
            final dto = WorkoutDto.fromJson(testCase);
            final entity = dto.toEntity();
            final backToJson = dto.toJson();

            // Verificar que el ciclo completo preserva los datos
            expect(dto.id, equals(testCase['id']));
            expect(dto.name, equals(testCase['name']));
            expect(dto.startTime, equals(testCase['startTime']));
            expect(entity.id, equals(testCase['id']));
            expect(entity.name, equals(testCase['name']));
            expect(backToJson['id'], equals(testCase['id']));
            expect(backToJson['name'], equals(testCase['name']));
            expect(backToJson['startTime'], equals(testCase['startTime']));
          }
        },
      );
    });

    group('Preservación de lógica de negocio existente', () {
      test(
        'debería preservar validación y conversión de fechas en UserDto',
        () {
          final userJson = {
            'id': 1,
            'username': 'date_test',
            'email': 'date@test.com',
            'isPremium': false,
            'languagePreference': 'es',
            'createdAt': '2024-03-15T14:30:45Z',
            'publicProfile': true,
          };

          final dto = UserDto.fromJson(userJson);
          final entity = dto.toEntity();

          // Verificar que la conversión de fecha funciona correctamente
          expect(entity.createdAt, isNotNull);
          expect(entity.createdAt!.year, equals(2024));
          expect(entity.createdAt!.month, equals(3));
          expect(entity.createdAt!.day, equals(15));
          expect(entity.createdAt!.hour, equals(14));
          expect(entity.createdAt!.minute, equals(30));
          expect(entity.createdAt!.second, equals(45));
        },
      );

      test('debería preservar manejo de listas vacías en ExerciseDto', () {
        final exerciseJson = {
          'id': 1,
          'name': 'Solo Exercise',
          'description': 'Exercise with no secondary muscles',
          'primaryMuscle': 'Chest',
          'category': 'Bodyweight',
          'secondaryMuscles': [],
        };

        final dto = ExerciseDto.fromJson(exerciseJson);
        final entity = dto.toEntity();

        expect(dto.secondaryMuscles, isEmpty);
        expect(entity.secondaryMuscles, isEmpty);
        expect(dto.toJson()['secondaryMuscles'], isEmpty);
      });

      test(
        'debería preservar manejo de campos opcionales válidos en RoutineDto',
        () {
          final routineJson = {
            'id': null, // ID nulo válido para rutinas nuevas
            'name': 'New Routine',
            'description': 'Fresh routine',
            'userId': 1,
            'exercises': [],
            'createdAt':
                null, // createdAt nulo válido para rutinas no guardadas
          };

          final dto = RoutineDto.fromJson(routineJson);
          final entity = dto.toEntity();

          expect(dto.id, isNull);
          expect(dto.createdAt, isNull);
          expect(entity.id, isNull);
          expect(entity.createdAt, isNull);
          expect(dto.name, equals('New Routine'));
          expect(entity.name, equals('New Routine'));
        },
      );
    });
  });
}
