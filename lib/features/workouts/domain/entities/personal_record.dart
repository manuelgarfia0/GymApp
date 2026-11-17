/// Categorías de récord personal que puede superar una serie completada.
enum PersonalRecordType {
  maxWeight,
  repRecord,
  estimated1Rm,
  firstBenchmark,
}

/// Mejor registro histórico consolidado para un ejercicio concreto.
class ExerciseHistoricalBest {
  final int exerciseId;
  final String exerciseName;
  final double maxWeight;
  final int maxRepsAtMaxWeight;
  final double maxEstimated1Rm;

  const ExerciseHistoricalBest({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.maxRepsAtMaxWeight,
    required this.maxEstimated1Rm,
  });

  /// Formatea un peso eliminando decimales `.0` innecesarios.
  static String formatWeight(double weight) {
    if (weight == weight.truncateToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  /// Resumen legible para mostrar en la cabecera del ejercicio durante el entreno.
  String formatSummary() {
    return '${formatWeight(maxWeight)} kg × $maxRepsAtMaxWeight '
        '(1RM ~${maxEstimated1Rm.round()} kg)';
  }
}

/// Logro de récord personal alcanzado en una serie durante un entrenamiento.
class PersonalRecordAchievement {
  final int exerciseId;
  final String exerciseName;
  final int setNumber;
  final double weight;
  final int reps;
  final double estimated1Rm;
  final double? previousMaxWeight;
  final double? previousMax1Rm;
  final Set<PersonalRecordType> types;

  const PersonalRecordAchievement({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.estimated1Rm,
    this.previousMaxWeight,
    this.previousMax1Rm,
    required this.types,
  });

  String get badgeLabel => '🏆 Nuevo PR';

  String get performanceLabel =>
      '${ExerciseHistoricalBest.formatWeight(weight)} kg × $reps';

  /// Explica de forma breve qué marca histórica se ha batido.
  String get improvementLabel {
    if (types.contains(PersonalRecordType.firstBenchmark)) {
      return '1ª marca: $performanceLabel · 1RM ~${estimated1Rm.round()} kg';
    }
    if (types.contains(PersonalRecordType.maxWeight) &&
        previousMaxWeight != null) {
      final diff = weight - previousMaxWeight!;
      return '+${ExerciseHistoricalBest.formatWeight(diff)} kg en peso máximo';
    }
    if (types.contains(PersonalRecordType.estimated1Rm) &&
        previousMax1Rm != null) {
      final diff = estimated1Rm - previousMax1Rm!;
      return '+${diff.toStringAsFixed(1)} kg en 1RM estimado';
    }
    if (types.contains(PersonalRecordType.repRecord)) {
      return 'Más repeticiones con ${ExerciseHistoricalBest.formatWeight(weight)} kg';
    }
    return performanceLabel;
  }
}
