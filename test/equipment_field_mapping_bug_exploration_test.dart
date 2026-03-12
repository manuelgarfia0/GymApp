import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/data/models/exercise_dto.dart';

/// **Valida: Requisitos 1.1, 1.2, 2.1, 2.2**
///
/// Test de Exploración de Condición de Bug para Mapeo de Campo Equipment
///
/// CRÍTICO: Este test DEBE FALLAR en el código actual para probar que el bug existe.
/// El fallo demuestra que cuando la API envía el campo "equipment", el ExerciseDto
/// no puede mapearlo correctamente porque busca el campo "category".
///
/// NO corregir el código cuando este test falle - el fallo es el resultado esperado
/// que prueba que la condición del bug existe.
///
/// **Property 1: Bug Condition** - Equipment Field Mapping Investigation
void main() {
  group('Exploración de Condición de Bug - Mapeo de Campo Equipment', () {
    group('Investigación de estructura de respuesta API', () {
      test('debería mapear correctamente cuando API envía campo equipment', () {
        // Simula respuesta JSON del backend Spring Boot con campo "equipment"
        // Este es el caso donde el backend envía "equipment" pero el DTO busca "category"
        final jsonWithEquipmentField = {
          'id': 1,
          'name': 'Bench Press',
          'description': 'Chest exercise with barbell',
          'equipment': 'Barbell', // Backend envía "equipment"
          'primaryMuscle': 'Chest',
          'secondaryMuscles': ['Triceps', 'Shoulders'],
        };

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        // El fallo demuestra que ExerciseDto.fromJson() no puede mapear "equipment" a "category"
        final dto = ExerciseDto.fromJson(jsonWithEquipmentField);

        // Logging para investigar la estructura real
        print('🔍 DTO creado: $dto');
        print('🔍 Campo category mapeado: ${dto.category}');
        print(
          '🔍 JSON original equipment: ${jsonWithEquipmentField['equipment']}',
        );

        // Esta aserción DEBE FALLAR si el backend envía "equipment" pero el DTO mapea "category"
        expect(
          dto.category,
          equals('Barbell'),
          reason:
              'El campo equipment del backend debería mapearse correctamente a category en el DTO',
        );

        // Verificar que otros campos se mapean correctamente (para confirmar que solo equipment falla)
        expect(dto.name, equals('Bench Press'));
        expect(dto.description, equals('Chest exercise with barbell'));
        expect(dto.id, equals(1));
      });

      test('debería manejar múltiples ejercicios con campo equipment', () {
        // Simula respuesta de múltiples ejercicios con campo "equipment"
        final exercisesWithEquipment = [
          {
            'id': 1,
            'name': 'Bench Press',
            'description': 'Chest exercise',
            'equipment': 'Barbell',
            'primaryMuscle': 'Chest',
            'secondaryMuscles': ['Triceps'],
          },
          {
            'id': 2,
            'name': 'Squat',
            'description': 'Leg exercise',
            'equipment': 'Barbell',
            'primaryMuscle': 'Quadriceps',
            'secondaryMuscles': ['Glutes', 'Hamstrings'],
          },
          {
            'id': 3,
            'name': 'Push-up',
            'description': 'Bodyweight chest exercise',
            'equipment': 'Bodyweight',
            'primaryMuscle': 'Chest',
            'secondaryMuscles': ['Triceps', 'Shoulders'],
          },
        ];

        // EXPECTATIVA: Este test DEBE FALLAR en código sin corregir
        // Demuestra inconsistencia en el mapeo a través de múltiples ejercicios
        final dtos = exercisesWithEquipment
            .map((json) => ExerciseDto.fromJson(json))
            .toList();

        print('🔍 Múltiples ejercicios procesados: ${dtos.length}');
        for (int i = 0; i < dtos.length; i++) {
          print(
            '🔍 Ejercicio ${i + 1}: ${dtos[i].name} - category: ${dtos[i].category}',
          );
        }

        // Estas aserciones DEBEN FALLAR si el mapeo de equipment no funciona
        expect(
          dtos[0].category,
          equals('Barbell'),
          reason: 'Bench Press debería tener equipment Barbell',
        );
        expect(
          dtos[1].category,
          equals('Barbell'),
          reason: 'Squat debería tener equipment Barbell',
        );
        expect(
          dtos[2].category,
          equals('Bodyweight'),
          reason: 'Push-up debería tener equipment Bodyweight',
        );

        // Verificar que otros campos se mapean correctamente
        expect(dtos.every((dto) => dto.name.isNotEmpty), isTrue);
        expect(dtos.every((dto) => dto.id > 0), isTrue);
      });

      test('debería fallar cuando API envía equipment pero DTO espera category', () {
        // Test específico para demostrar la discrepancia entre nombres de campo
        final jsonWithEquipmentOnly = {
          'id': 4,
          'name': 'Deadlift',
          'description': 'Full body exercise',
          'equipment': 'Barbell', // Solo campo "equipment", no "category"
          'primaryMuscle': 'Hamstrings',
          'secondaryMuscles': ['Glutes', 'Lower Back'],
        };

        final dto = ExerciseDto.fromJson(jsonWithEquipmentOnly);

        print('🔍 Test discrepancia - DTO: $dto');
        print('🔍 JSON equipment: ${jsonWithEquipmentOnly['equipment']}');
        print('🔍 DTO category: ${dto.category}');

        // EXPECTATIVA CRÍTICA: Este test DEBE FALLAR
        // Si el backend envía "equipment" pero el DTO busca "category", category será null
        expect(
          dto.category,
          isNotNull,
          reason:
              'El campo category no debería ser null cuando el backend envía equipment',
        );

        expect(
          dto.category,
          equals('Barbell'),
          reason:
              'El campo equipment del backend debería mapearse a category en el DTO',
        );
      });

      test('debería documentar contraejemplos encontrados', () {
        // Test para documentar los contraejemplos específicos que demuestran el bug
        final testCases = [
          {
            'name': 'Barbell Row',
            'equipment': 'Barbell',
            'expectedCategory': 'Barbell',
          },
          {
            'name': 'Dumbbell Curl',
            'equipment': 'Dumbbell',
            'expectedCategory': 'Dumbbell',
          },
          {
            'name': 'Cable Fly',
            'equipment': 'Cable',
            'expectedCategory': 'Cable',
          },
        ];

        final counterExamples = <String>[];

        for (final testCase in testCases) {
          final json = {
            'id': 1,
            'name': testCase['name'],
            'description': 'Test exercise',
            'equipment': testCase['equipment'],
            'primaryMuscle': 'Test',
            'secondaryMuscles': <String>[],
          };

          final dto = ExerciseDto.fromJson(json);

          if (dto.category != testCase['expectedCategory']) {
            counterExamples.add(
              'API envía equipment: "${testCase['equipment']}" pero DTO.category es: ${dto.category}',
            );
          }
        }

        print('🔍 Contraejemplos encontrados:');
        for (final example in counterExamples) {
          print('🔍 - $example');
        }

        // EXPECTATIVA: Este test DEBE FALLAR si hay contraejemplos
        // Los contraejemplos demuestran que el bug existe
        expect(
          counterExamples,
          isEmpty,
          reason:
              'No deberían existir contraejemplos si el mapeo funciona correctamente. '
              'Contraejemplos encontrados: $counterExamples',
        );
      });
    });

    group('Verificación de comportamiento de otros campos (control)', () {
      test('debería mapear correctamente campos que no son equipment', () {
        // Test de control para verificar que otros campos se mapean correctamente
        // Esto confirma que el problema es específico del campo equipment/category
        final jsonWithAllFields = {
          'id': 5,
          'name': 'Test Exercise',
          'description': 'Test description',
          'equipment': 'Test Equipment', // Este debería fallar
          'primaryMuscle': 'Test Muscle',
          'secondaryMuscles': ['Secondary1', 'Secondary2'],
        };

        final dto = ExerciseDto.fromJson(jsonWithAllFields);

        // Estos campos DEBERÍAN mapearse correctamente (comportamiento de control)
        expect(dto.id, equals(5));
        expect(dto.name, equals('Test Exercise'));
        expect(dto.description, equals('Test description'));
        expect(dto.primaryMuscle, equals('Test Muscle'));
        expect(dto.secondaryMuscles, equals(['Secondary1', 'Secondary2']));

        print('🔍 Campos de control mapeados correctamente');
        print('🔍 Pero equipment -> category: ${dto.category}');

        // Solo este campo debería fallar
        expect(
          dto.category,
          equals('Test Equipment'),
          reason: 'Solo el mapeo de equipment a category debería fallar',
        );
      });
    });
  });
}
