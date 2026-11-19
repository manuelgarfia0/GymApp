import 'dart:convert';
import '../../features/workouts/domain/entities/workout.dart';
import '../utils/weight_converter.dart';

/// Serializador de historial de entrenamientos a formatos portables (CSV / JSON).
class WorkoutExportService {
  static const String _csvHeader =
      'workout_id,workout_name,start_time,end_time,duration_seconds,'
      'exercise_id,exercise_name,set_number,weight,weight_unit,reps,is_warmup,notes';

  static String toCsv(
    List<Workout> workouts, {
    WeightUnit unit = WeightUnit.kg,
  }) {
    final buffer = StringBuffer()..writeln(_csvHeader);

    for (final w in workouts) {
      final durationSec = w.endTime != null
          ? w.endTime!.difference(w.startTime).inSeconds.clamp(0, 864000)
          : 0;
      final baseCols = [
        w.id?.toString() ?? '',
        _escapeCsv(w.name),
        w.startTime.toIso8601String(),
        w.endTime?.toIso8601String() ?? '',
        durationSec.toString(),
      ];

      if (w.sets.isEmpty) {
        buffer.writeln([
          ...baseCols,
          '',
          '',
          '',
          '',
          unit.code,
          '',
          '',
          _escapeCsv(w.notes ?? ''),
        ].join(','));
        continue;
      }

      for (final s in w.sets) {
        final convertedWeight = WeightConverter.fromKg(s.weight, unit);
        final formattedWeight = convertedWeight.toStringAsFixed(2);
        final note = (s.notes != null && s.notes!.trim().isNotEmpty)
            ? s.notes!
            : (w.notes ?? '');
        buffer.writeln([
          ...baseCols,
          s.exerciseId.toString(),
          _escapeCsv(s.exerciseName ?? ''),
          s.setNumber.toString(),
          formattedWeight,
          unit.code,
          s.reps.toString(),
          s.isWarmup ? 'true' : 'false',
          _escapeCsv(note),
        ].join(','));
      }
    }

    return buffer.toString();
  }

  static String toJson(
    List<Workout> workouts, {
    WeightUnit unit = WeightUnit.kg,
  }) {
    final payload = {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'weightUnit': unit.code,
      'totalWorkouts': workouts.length,
      'workouts': workouts.map((w) {
        final durationSec = w.endTime
            ?.difference(w.startTime)
            .inSeconds
            .clamp(0, 864000);
        return {
          'id': w.id,
          'name': w.name,
          'notes': w.notes,
          'startTime': w.startTime.toIso8601String(),
          'endTime': w.endTime?.toIso8601String(),
          'durationSeconds': durationSec,
          'routineId': w.routineId,
          'sets': w.sets.map((s) {
            final convertedWeight = double.parse(
              WeightConverter.fromKg(s.weight, unit).toStringAsFixed(2),
            );
            return {
              'id': s.id,
              'exerciseId': s.exerciseId,
              'exerciseName': s.exerciseName,
              'setNumber': s.setNumber,
              'weight': convertedWeight,
              'weightUnit': unit.code,
              'reps': s.reps,
              'isWarmup': s.isWarmup,
              'notes': s.notes,
            };
          }).toList(),
        };
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
