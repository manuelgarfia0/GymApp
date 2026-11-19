import '../entities/exercise.dart';

/// Valida si una serie tiene los valores mínimos necesarios antes de marcarse
/// como completada durante un entrenamiento activo.
class WorkoutSetValidator {
  static bool isBodyweightExercise(Exercise exercise) {
    final normalized = (exercise.category ?? '').trim().toLowerCase();
    return normalized == 'bodyweight' || normalized == 'peso corporal';
  }

  /// Devuelve `null` si la serie es válida para completarse, o un mensaje claro
  /// explicando qué falta (peso y/o repeticiones).
  static String? validateForCompletion({
    required double? weight,
    required int? reps,
    required Exercise exercise,
  }) {
    final isBodyweight = isBodyweightExercise(exercise);
    if (weight == null) {
      return isBodyweight
          ? 'Introduce el peso (0 si es sin lastre) antes de completar la serie'
          : 'Introduce el peso antes de completar la serie';
    }
    if (weight < 0) {
      return 'El peso no puede ser negativo';
    }
    if (!isBodyweight && weight <= 0) {
      return 'El peso debe ser mayor que 0 kg para completar la serie';
    }
    if (reps == null || reps <= 0) {
      return 'Introduce las repeticiones antes de completar la serie';
    }
    return null;
  }
}
