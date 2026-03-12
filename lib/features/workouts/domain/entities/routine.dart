/// Entidad Dart pura que representa una rutina en la capa de dominio.
/// No contiene dependencias de Flutter y representa el concepto de negocio de una rutina de ejercicios.
class Routine {
  final int? id;
  final String name;
  final String? description; // Cambiado a nullable para consistencia con DTO
  final int userId;
  final List<RoutineExercise> exercises;
  final DateTime? createdAt;

  const Routine({
    this.id,
    required this.name,
    this.description, // Cambiado a opcional para manejar valores nulos
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
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      userId,
      exercises.length,
      createdAt,
    );
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'Routine(id: $id, name: $name, userId: $userId, exercises: ${exercises.length})';
  }
}

/// Entidad Dart pura que representa un ejercicio dentro de una rutina.
/// Define los parámetros de cómo debe realizarse un ejercicio en una rutina.
class RoutineExercise {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;

  const RoutineExercise({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.restSeconds,
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
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      exerciseId,
      exerciseName,
      orderIndex,
      sets,
      reps,
      restSeconds,
      notes,
    );
  }

  @override
  String toString() {
    return 'RoutineExercise(exerciseId: $exerciseId, sets: $sets, reps: $reps)';
  }
}
