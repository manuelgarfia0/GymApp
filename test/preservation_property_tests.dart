import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';
import 'package:gym_app/features/workouts/domain/entities/exercise.dart';

/// **Valida: Requisitos 3.1, 3.2, 3.3**
///
/// Tests de Preservación de Propiedades para Mapeo de Campos No-Equipment
///
/// IMPORTANTE: Metodología de observación primero
/// - Observar comportamiento en código SIN CORREGIR para campos no-equipment
/// - Escribir tests que capturen patrones de comportamiento observados
/// - Estos tests DEBEN PASAR en código sin corregir (confirma comportamiento base a preservar)
///
/// **Property 2: Preservation** - Non-Equipment Field Mapping
void main() {
  group('Tests de Preservación - Mapeo de Campos No-Equipment', () {
    group('Preservación de mapeo de campo name', () {
      test('name field maps correctly from JSON to DTO', () {
        // Casos de prueba para nombres de ejercicios
        final testCases = [
          'Bench Press',
          'Squat',
          'Deadlift',
          'Push-up',
          'Pull-up',
          'Overhead Press',
          'Barbell Row',
          'Dumbbell Curl',
          'Tricep Dip',
          'Plank',
        ];

        for (final exerciseName in testCases) {
          // Crear JSON con campo name válido
          final json = {
            'id': 1,
            'name': exerciseName,
            'description': 'Test description',
            'category':
                'Test Category', // Usar category (no equipment) para evitar el bug
            'primaryMuscle': 'Test Muscle',
            'secondaryMuscles': ['Secondary1', 'Secondary2'],
          };

          // Mapear JSON a DTO usando código actual (sin corregir)
          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Confirma que el mapeo de name funciona correctamente
          expect(
            dto.name,
            equals(exerciseName),
            reason:
                'El campo name debe mapearse correctamente del JSON al DTO para $exerciseName',
          );

          // Verificar que el name no es null ni vacío
          expect(dto.name.isNotEmpty, isTrue);
        }
      });

      test('name field handles edge cases correctly', () {
        // Casos edge para name
        final edgeCases = [
          '', // Nombre vacío
          'A', // Nombre de un carácter
          'Very Long Exercise Name With Multiple Words And Spaces',
          'Exercise-With-Hyphens',
          'Exercise_With_Underscores',
          'Exercise123',
        ];

        for (final exerciseName in edgeCases) {
          final json = {
            'id': 1,
            'name': exerciseName,
            'description': 'Test description',
            'category': 'Test Category',
            'primaryMuscle': 'Test Muscle',
            'secondaryMuscles': <String>[],
          };

          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Observar comportamiento actual para casos edge
          // El test debe pasar para confirmar el comportamiento base
          if (exerciseName.isEmpty) {
            // Si el nombre está vacío, verificar comportamiento por defecto
            expect(dto.name, isNotNull);
            // Observar si se usa un valor por defecto
            print('🔍 Nombre vacío mapeado como: "${dto.name}"');
          } else {
            expect(dto.name, equals(exerciseName));
          }
        }
      });
    });

    group('Preservación de mapeo de campo description', () {
      test('description field maps correctly from JSON to DTO', () {
        // Casos de prueba para descripciones
        final testCases = [
          'Chest exercise with barbell',
          'Leg exercise for quadriceps',
          'Full body compound movement',
          'Bodyweight upper body exercise',
          'Core strengthening exercise',
          null, // Descripción null
          '', // Descripción vacía
        ];

        for (final description in testCases) {
          final json = {
            'id': 1,
            'name': 'Test Exercise',
            'description': description,
            'category': 'Test Category',
            'primaryMuscle': 'Test Muscle',
            'secondaryMuscles': <String>[],
          };

          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Confirma que el mapeo de description funciona correctamente
          expect(
            dto.description,
            equals(description),
            reason:
                'El campo description debe mapearse correctamente del JSON al DTO',
          );

          print(
            '🔍 Description "$description" mapeado como: "${dto.description}"',
          );
        }
      });
    });

    group('Preservación de mapeo de campo primaryMuscle', () {
      test('primaryMuscle field maps correctly from JSON to DTO', () {
        // Casos de prueba para músculos primarios
        final testCases = [
          'Chest',
          'Quadriceps',
          'Hamstrings',
          'Shoulders',
          'Triceps',
          'Biceps',
          'Back',
          'Core',
          null, // Músculo primario null
        ];

        for (final primaryMuscle in testCases) {
          final json = {
            'id': 1,
            'name': 'Test Exercise',
            'description': 'Test description',
            'category': 'Test Category',
            'primaryMuscle': primaryMuscle,
            'secondaryMuscles': <String>[],
          };

          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Confirma que el mapeo de primaryMuscle funciona correctamente
          expect(
            dto.primaryMuscle,
            equals(primaryMuscle),
            reason:
                'El campo primaryMuscle debe mapearse correctamente del JSON al DTO',
          );

          print(
            '🔍 PrimaryMuscle "$primaryMuscle" mapeado como: "${dto.primaryMuscle}"',
          );
        }
      });
    });

    group('Preservación de mapeo de campo secondaryMuscles', () {
      test('secondaryMuscles field maps correctly from JSON to DTO', () {
        // Casos de prueba para listas de músculos secundarios
        final testCases = [
          <String>[], // Lista vacía
          ['Triceps'], // Un músculo
          ['Triceps', 'Shoulders'], // Múltiples músculos
          ['Glutes', 'Hamstrings', 'Calves'], // Tres músculos
          null, // Lista null
        ];

        for (final secondaryMuscles in testCases) {
          final json = {
            'id': 1,
            'name': 'Test Exercise',
            'description': 'Test description',
            'category': 'Test Category',
            'primaryMuscle': 'Test Muscle',
            'secondaryMuscles': secondaryMuscles,
          };

          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Confirma que el mapeo de secondaryMuscles funciona correctamente
          if (secondaryMuscles == null) {
            // Si es null, debe convertirse a lista vacía según implementación actual
            expect(dto.secondaryMuscles, equals(<String>[]));
            print(
              '🔍 SecondaryMuscles null mapeado como: ${dto.secondaryMuscles}',
            );
          } else {
            expect(
              dto.secondaryMuscles,
              equals(secondaryMuscles),
              reason:
                  'El campo secondaryMuscles debe mapearse correctamente del JSON al DTO',
            );
            print(
              '🔍 SecondaryMuscles $secondaryMuscles mapeado como: ${dto.secondaryMuscles}',
            );
          }
        }
      });

      test('secondaryMuscles handles complex list scenarios', () {
        // Casos complejos para secondaryMuscles
        final complexCases = [
          [
            'Muscle1',
            'Muscle2',
            'Muscle3',
            'Muscle4',
            'Muscle5',
          ], // Lista larga
          ['Single'], // Un elemento
          ['A', 'B', 'C'], // Nombres cortos
          ['Very Long Muscle Name', 'Another Long Name'], // Nombres largos
        ];

        for (final secondaryMuscles in complexCases) {
          final json = {
            'id': 1,
            'name': 'Test Exercise',
            'description': 'Test description',
            'category': 'Test Category',
            'primaryMuscle': 'Test Muscle',
            'secondaryMuscles': secondaryMuscles,
          };

          final dto = ExerciseDto.fromJson(json);

          // EXPECTATIVA: Observar comportamiento actual para listas complejas
          expect(dto.secondaryMuscles, equals(secondaryMuscles));
          expect(dto.secondaryMuscles.length, equals(secondaryMuscles.length));

          print('🔍 Lista compleja $secondaryMuscles mapeada correctamente');
        }
      });
    });

    group('Preservación de conversión DTO a Entity', () {
      test('DTO to Entity conversion works correctly for all non-equipment fields', () {
        // Casos de prueba para DTOs completos
        final testCases = [
          {
            'id': 1,
            'name': 'Bench Press',
            'description': 'Chest exercise',
            'category':
                'Barbell', // Usar category para evitar el bug de equipment
            'primaryMuscle': 'Chest',
            'secondaryMuscles': ['Triceps', 'Shoulders'],
          },
          {
            'id': 2,
            'name': 'Squat',
            'description': null,
            'category': 'Barbell',
            'primaryMuscle': null,
            'secondaryMuscles': <String>[],
          },
          {
            'id': 3,
            'name': 'Push-up',
            'description': 'Bodyweight exercise',
            'category': null,
            'primaryMuscle': 'Chest',
            'secondaryMuscles': ['Triceps'],
          },
        ];

        for (final jsonData in testCases) {
          // Crear DTO desde JSON
          final dto = ExerciseDto.fromJson(jsonData);

          // Convertir DTO a Entity
          final entity = dto.toEntity();

          // EXPECTATIVA: Este test DEBE PASAR en código sin corregir
          // Confirma que la conversión DTO->Entity preserva todos los campos no-equipment
          expect(
            entity.id,
            equals(dto.id),
            reason: 'El campo id debe preservarse en la conversión DTO->Entity',
          );

          expect(
            entity.name,
            equals(dto.name),
            reason:
                'El campo name debe preservarse en la conversión DTO->Entity',
          );

          expect(
            entity.description,
            equals(dto.description),
            reason:
                'El campo description debe preservarse en la conversión DTO->Entity',
          );

          expect(
            entity.primaryMuscle,
            equals(dto.primaryMuscle),
            reason:
                'El campo primaryMuscle debe preservarse en la conversión DTO->Entity',
          );

          expect(
            entity.secondaryMuscles,
            equals(dto.secondaryMuscles),
            reason:
                'El campo secondaryMuscles debe preservarse en la conversión DTO->Entity',
          );

          // Verificar que la lista de secondaryMuscles es una copia independiente
          expect(
            identical(entity.secondaryMuscles, dto.secondaryMuscles),
            isFalse,
            reason:
                'secondaryMuscles debe ser una copia independiente, no la misma referencia',
          );

          print(
            '🔍 Conversión DTO->Entity exitosa para ejercicio: ${entity.name}',
          );
        }
      });

      test('Entity maintains clean separation between data and domain layers', () {
        // Casos de prueba para separación de capas
        final testCases = [
          {
            'id': 10,
            'name': 'Deadlift',
            'description': 'Full body exercise',
            'category': 'Barbell',
            'primaryMuscle': 'Hamstrings',
            'secondaryMuscles': ['Glutes', 'Lower Back', 'Traps'],
          },
          {
            'id': 20,
            'name': 'Plank',
            'description': 'Core exercise',
            'category': 'Bodyweight',
            'primaryMuscle': 'Core',
            'secondaryMuscles': ['Shoulders', 'Glutes'],
          },
        ];

        for (final jsonData in testCases) {
          final dto = ExerciseDto.fromJson(jsonData);
          final entity = dto.toEntity();

          // EXPECTATIVA: Verificar separación limpia entre capas
          // La entidad debe ser independiente del DTO
          expect(entity, isA<Exercise>());
          expect(dto, isA<ExerciseDto>());

          // Verificar que la entidad tiene los mismos datos pero es independiente
          expect(entity.id, equals(dto.id));
          expect(entity.name, equals(dto.name));
          expect(entity.description, equals(dto.description));
          expect(entity.primaryMuscle, equals(dto.primaryMuscle));

          // Modificar la lista en el DTO no debe afectar la entidad
          if (dto.secondaryMuscles.isNotEmpty) {
            final originalEntityMuscles = List<String>.from(
              entity.secondaryMuscles,
            );
            dto.secondaryMuscles.clear(); // Modificar DTO

            expect(
              entity.secondaryMuscles,
              equals(originalEntityMuscles),
              reason:
                  'La entidad debe ser independiente de modificaciones en el DTO',
            );

            print('🔍 Separación de capas verificada para: ${entity.name}');
          }
        }
      });
    });

    group('Preservación de comportamiento de mapeo completo', () {
      test('complete mapping behavior is preserved for non-equipment fields', () {
        // Casos de prueba para flujo completo
        final testCases = [
          {
            'id': 100,
            'name': 'Complete Exercise 1',
            'description': 'Complete description 1',
            'category': 'Complete Category 1',
            'primaryMuscle': 'Complete Primary 1',
            'secondaryMuscles': [
              'Complete Secondary 1',
              'Complete Secondary 2',
            ],
          },
          {
            'id': 200,
            'name': 'Complete Exercise 2',
            'description': null,
            'category': 'Complete Category 2',
            'primaryMuscle': null,
            'secondaryMuscles': <String>[],
          },
          {
            'id': 300,
            'name': 'Complete Exercise 3',
            'description': 'Complete description 3',
            'category': null,
            'primaryMuscle': 'Complete Primary 3',
            'secondaryMuscles': ['Complete Secondary 3'],
          },
        ];

        for (final jsonData in testCases) {
          // Proceso completo: JSON -> DTO -> Entity
          final dto = ExerciseDto.fromJson(jsonData);
          final entity = dto.toEntity();

          // EXPECTATIVA: Todo el flujo debe funcionar correctamente para campos no-equipment
          // Verificar que todos los campos no-equipment se preservan a través del flujo completo

          // Verificar mapeo JSON -> DTO
          expect(dto.id, equals(jsonData['id']));
          expect(dto.name, equals(jsonData['name']));
          expect(dto.description, equals(jsonData['description']));
          expect(dto.primaryMuscle, equals(jsonData['primaryMuscle']));

          final expectedSecondaryMuscles =
              jsonData['secondaryMuscles'] as List<String>?;
          if (expectedSecondaryMuscles == null) {
            expect(dto.secondaryMuscles, equals(<String>[]));
          } else {
            expect(dto.secondaryMuscles, equals(expectedSecondaryMuscles));
          }

          // Verificar mapeo DTO -> Entity
          expect(entity.id, equals(dto.id));
          expect(entity.name, equals(dto.name));
          expect(entity.description, equals(dto.description));
          expect(entity.primaryMuscle, equals(dto.primaryMuscle));
          expect(entity.secondaryMuscles, equals(dto.secondaryMuscles));

          // Verificar que el flujo completo preserva los datos originales (excepto transformaciones esperadas)
          expect(entity.id, equals(jsonData['id']));
          expect(entity.name, equals(jsonData['name']));
          expect(entity.description, equals(jsonData['description']));
          expect(entity.primaryMuscle, equals(jsonData['primaryMuscle']));

          print(
            '🔍 Flujo completo JSON->DTO->Entity exitoso para: ${entity.name}',
          );
        }
      });
    });
  });
}
