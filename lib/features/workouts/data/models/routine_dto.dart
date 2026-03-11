import '../../domain/entities/routine.dart';

/// Data Transfer Object for Routine
/// Handles JSON serialization/deserialization with the Spring Boot backend
class RoutineDto {
  final int? id;
  final String name;
  final String description;
  final int userId;
  final List<RoutineExerciseDto> exercises;
  final String? createdAt;

  const RoutineDto({
    this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.exercises,
    this.createdAt,
  });

  /// Creates RoutineDto from JSON response from Spring Boot API
  factory RoutineDto.fromJson(Map<String, dynamic> json) {
    return RoutineDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
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

  /// Converts RoutineDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'userId': userId,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineDto &&
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
    return 'RoutineDto(id: $id, name: $name, userId: $userId, exercises: ${exercises.length})';
  }
}

/// Data Transfer Object for RoutineExercise
/// Handles JSON serialization/deserialization for exercises within routines
class RoutineExerciseDto {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;

  const RoutineExerciseDto({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
  });

  /// Creates RoutineExerciseDto from JSON response from Spring Boot API
  factory RoutineExerciseDto.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseDto(
      id: json['id'] as int?,
      exerciseId: json['exerciseId'] as int,
      exerciseName: json['exerciseName'] as String?,
      orderIndex: json['orderIndex'] as int,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      restSeconds: json['restSeconds'] as int,
      notes: json['notes'] as String?,
    );
  }

  /// Converts RoutineExerciseDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exerciseId': exerciseId,
      if (exerciseName != null) 'exerciseName': exerciseName,
      'orderIndex': orderIndex,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      if (notes != null) 'notes': notes,
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
  RoutineExercise toEntity() {
    return RoutineExercise(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      orderIndex: orderIndex,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
      notes: notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineExerciseDto &&
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
    return 'RoutineExerciseDto(exerciseId: $exerciseId, sets: $sets, reps: $reps)';
  }
}
