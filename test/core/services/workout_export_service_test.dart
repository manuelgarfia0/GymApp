import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/services/workout_export_service.dart';
import 'package:gym_app/core/utils/weight_converter.dart';
import 'package:gym_app/features/workouts/domain/entities/workout.dart';

void main() {
  group('WorkoutExportService', () {
    final sampleWorkouts = [
      Workout(
        id: 12,
        userId: 3,
        name: 'Push, Heavy',
        notes: 'Good "pump" day',
        startTime: DateTime(2026, 11, 1, 10, 0),
        endTime: DateTime(2026, 11, 1, 11, 0),
        sets: [
          WorkoutSet(
            id: 1,
            exerciseId: 101,
            exerciseName: 'Bench Press',
            exerciseOrder: 1,
            setNumber: 1,
            weight: 100.0,
            reps: 5,
            timestamp: DateTime(2026, 11, 1, 10, 15),
          ),
        ],
      ),
    ];

    test('exports CSV with proper RFC-4180 escaping and unit conversion', () {
      final csvKg = WorkoutExportService.toCsv(
        sampleWorkouts,
        unit: WeightUnit.kg,
      );
      expect(csvKg, contains('workout_id,workout_name,start_time'));
      expect(csvKg, contains('"Push, Heavy"'));
      expect(csvKg, contains('"Good ""pump"" day"'));
      expect(csvKg, contains(',100.00,kg,5,false,'));

      final csvLb = WorkoutExportService.toCsv(
        sampleWorkouts,
        unit: WeightUnit.lb,
      );
      expect(csvLb, contains(',220.46,lb,5,false,'));
    });

    test('exports valid structured JSON with converted weights', () {
      final jsonStr = WorkoutExportService.toJson(
        sampleWorkouts,
        unit: WeightUnit.lb,
      );
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['weightUnit'], 'lb');
      expect(decoded['totalWorkouts'], 1);
      final workouts = decoded['workouts'] as List<dynamic>;
      final sets = (workouts.first as Map<String, dynamic>)['sets'] as List;
      final firstSet = sets.first as Map<String, dynamic>;
      expect(firstSet['weight'], 220.46);
      expect(firstSet['weightUnit'], 'lb');
      expect(firstSet['durationSeconds'], isNull);
      expect((workouts.first as Map<String, dynamic>)['durationSeconds'], 3600);
    });
  });
}
