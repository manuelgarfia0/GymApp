class RoutineExerciseDTO {
  final int? id;
  final int exerciseId;
  final String? exerciseName; // Lo necesitaremos para pintar la UI
  final int orderIndex;
  final int sets;
  final int reps;
  final int restSeconds;
  final String? notes;

  RoutineExerciseDTO({
    this.id,
    required this.exerciseId,
    this.exerciseName,
    required this.orderIndex,
    required this.sets,
    required this.reps,
    this.restSeconds = 0,
    this.notes,
  });

  factory RoutineExerciseDTO.fromJson(Map<String, dynamic> json) {
    return RoutineExerciseDTO(
      id: json['id'],
      exerciseId: json['exerciseId'] ?? 0,
      exerciseName: json['exerciseName'],
      orderIndex: json['orderIndex'] ?? 0,
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      restSeconds: json['restSeconds'] ?? 0,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }
}

class RoutineDTO {
  final int? id;
  final String name;
  final String description;
  final int userId;
  final List<RoutineExerciseDTO> exercises;

  RoutineDTO({
    this.id,
    required this.name,
    required this.description,
    required this.userId,
    required this.exercises,
  });

  factory RoutineDTO.fromJson(Map<String, dynamic> json) {
    List<RoutineExerciseDTO> parsedExercises = [];
    if (json['exercises'] != null) {
      parsedExercises = (json['exercises'] as List)
          .map((i) => RoutineExerciseDTO.fromJson(i))
          .toList();
    }

    return RoutineDTO(
      id: json['id'],
      name: json['name'] ?? 'Unnamed Routine',
      description: json['description'] ?? '',
      userId: json['userId'] ?? 0,
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}