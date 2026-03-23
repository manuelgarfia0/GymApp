// lib/features/workouts/domain/entities/routine.dart

/// Entidad de dominio para una rutina de entrenamiento.
class Routine {
  final int? id;
  final String name;
  final String? description;
  final int userId;
  final List<RoutineExercise> exercises;
  final DateTime? createdAt;

  const Routine({
    this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.exercises,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Routine &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.userId == userId &&
        _listEquals(other.exercises, exercises) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, userId, exercises.length, createdAt);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'Routine(id: $id, name: $name, userId: $userId, exercises: ${exercises.length})';
}

/// Entidad de dominio para un ejercicio dentro de una rutina.
///
/// [targetWeight] almacena el peso objetivo sugerido para este ejercicio.
/// Se usa para pre-rellenar el entrenamiento cuando no existe historial previo.
/// El campo se envía al backend en el JSON pero es ignorado (campo extra),
/// ya que el peso real queda registrado en [WorkoutSet] al completar la sesión.
class RoutineExercise {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final double? targetWeight;
  final String? notes;

  const RoutineExercise({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.targetWeight,
    this.notes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineExercise &&
        other.id == id &&
        other.exerciseId == exerciseId &&
        other.exerciseName == exerciseName &&
        other.orderIndex == orderIndex &&
        other.sets == sets &&
        other.reps == reps &&
        other.restSeconds == restSeconds &&
        other.targetWeight == targetWeight &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
    id,
    exerciseId,
    exerciseName,
    orderIndex,
    sets,
    reps,
    restSeconds,
    targetWeight,
    notes,
  );

  @override
  String toString() =>
      'RoutineExercise(exerciseId: $exerciseId, sets: $sets, reps: $reps, targetWeight: $targetWeight)';
}
