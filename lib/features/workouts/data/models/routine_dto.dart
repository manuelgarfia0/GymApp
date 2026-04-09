import '../../domain/entities/routine.dart';

class RoutineDto {
  final int? id;
  final String name;
  final String? description;
  final int userId;
  final List<RoutineExerciseDto> exercises;
  final String? createdAt;

  const RoutineDto({
    this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.exercises,
    this.createdAt,
  });

  factory RoutineDto.fromJson(Map<String, dynamic> json) {
    return RoutineDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      userId: json['userId'] as int,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) => RoutineExerciseDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'userId': userId,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  Routine toEntity() {
    return Routine(
      id: id,
      name: name,
      description: description,
      userId: userId,
      exercises: exercises.map((e) => e.toEntity()).toList(),
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
    );
  }

  @override
  String toString() =>
      'RoutineDto(id: $id, name: $name, userId: $userId, exercises: ${exercises.length})';
}

/// DTO para un ejercicio dentro de una rutina.
///
/// [targetWeight] es un campo extra enviado al backend que éste ignora.
/// Se usa en Flutter para pre-poblar el peso sugerido al iniciar un workout.
class RoutineExerciseDto {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final double? targetWeight;
  final String? notes;

  const RoutineExerciseDto({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    this.restSeconds = 90,
    this.targetWeight,
    this.notes,
  });

  factory RoutineExerciseDto.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseDto(
      id: json['id'] as int?,
      exerciseId: json['exerciseId'] as int,
      exerciseName: json['exerciseName'] as String?,
      orderIndex: json['orderIndex'] as int? ?? 1,
      sets: json['sets'] as int? ?? 1,
      reps: json['reps'] as int? ?? 10,
      restSeconds: json['restSeconds'] as int? ?? 90,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exerciseId': exerciseId,
      if (exerciseName != null) 'exerciseName': exerciseName,
      'orderIndex': orderIndex,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (notes != null) 'notes': notes,
    };
  }

  RoutineExercise toEntity() {
    return RoutineExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      targetWeight: targetWeight,
      notes: notes,
    );
  }

  @override
  String toString() =>
      'RoutineExerciseDto(exerciseId: $exerciseId, sets: $sets, reps: $reps, restSeconds: $restSeconds)';
}
