import '../../domain/entities/workout.dart';

/// Data Transfer Object para Workout
class WorkoutDto {
  final int? id;
  final String name;
  final String? notes; // AÑADIDO: el backend tiene este campo
  final String? startTime;
  final String? endTime;
  final int userId;
  final int? routineId;
  final List<WorkoutSetDto> sets;

  const WorkoutDto({
    this.id,
    required this.name,
    this.notes,
    this.startTime,
    this.endTime,
    required this.userId,
    this.routineId,
    required this.sets,
  });

  factory WorkoutDto.fromJson(Map<String, dynamic> json) {
    return WorkoutDto(
      id: json['id'] as int?,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      userId: json['userId'] as int,
      routineId: json['routineId'] as int?,
      sets:
          (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSetDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (notes != null) 'notes': notes,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'userId': userId,
      if (routineId != null) 'routineId': routineId,
      'sets': sets.map((e) => e.toJson()).toList(),
    };
  }

  Workout toEntity() {
    return Workout(
      id: id,
      name: name,
      notes: notes,
      startTime: startTime != null
          ? DateTime.parse(startTime!)
          : DateTime.now(),
      endTime: endTime != null ? DateTime.parse(endTime!) : null,
      userId: userId,
      routineId: routineId,
      sets: sets.map((e) => e.toEntity()).toList(),
    );
  }
}

/// Data Transfer Object para WorkoutSet
/// Campos alineados con el backend Spring Boot WorkoutSetDTO:
///   - SIN "timestamp" (no existe en el backend)
///   - CON "isWarmup"   → Jackson serializa como "warmup"
///   - CON "isCompleted" → Jackson serializa como "completed"
class WorkoutSetDto {
  final int? id;
  final int exerciseId;
  final String? exerciseName;
  final int exerciseOrder;
  final int setNumber;
  final double weight;
  final int reps;
  final String? notes;
  final bool isWarmup;
  final bool isCompleted;

  const WorkoutSetDto({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.exerciseOrder,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.notes,
    this.isWarmup = false,
    this.isCompleted = false,
  });

  factory WorkoutSetDto.fromJson(Map<String, dynamic> json) {
    return WorkoutSetDto(
      id: json['id'] as int?,
      exerciseId: json['exerciseId'] as int,
      exerciseName: json['exerciseName'] as String?,
      exerciseOrder: json['exerciseOrder'] as int,
      setNumber: json['setNumber'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      notes: json['notes'] as String?,
      // Jackson serializa boolean isWarmup() como "warmup" (elimina el prefijo "is")
      isWarmup: json['warmup'] as bool? ?? json['isWarmup'] as bool? ?? false,
      isCompleted:
          json['completed'] as bool? ?? json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'exerciseId': exerciseId,
      if (exerciseName != null) 'exerciseName': exerciseName,
      'exerciseOrder': exerciseOrder,
      'setNumber': setNumber,
      'weight': weight,
      'reps': reps,
      if (notes != null) 'notes': notes,
      // El backend espera "isWarmup" e "isCompleted" como nombres de campo
      'isWarmup': isWarmup,
      'isCompleted': isCompleted,
    };
  }

  WorkoutSet toEntity() {
    return WorkoutSet(
      id: id,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      exerciseOrder: exerciseOrder,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      timestamp: DateTime.now(), // solo para uso local, no viene del backend
      notes: notes,
      isWarmup: isWarmup,
      isCompleted: isCompleted,
    );
  }
}
