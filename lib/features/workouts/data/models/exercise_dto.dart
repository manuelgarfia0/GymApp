import '../../domain/entities/exercise.dart';

/// Data Transfer Object for Exercise
/// Handles JSON serialization/deserialization with the Spring Boot backend
class ExerciseDto {
  final int id;
  final String name;
  final String description;
  final String primaryMuscle;
  final String equipment;
  final List<String> secondaryMuscles;

  const ExerciseDto({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    required this.equipment,
    required this.secondaryMuscles,
  });

  /// Creates ExerciseDto from JSON response from Spring Boot API
  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    return ExerciseDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryMuscle: json['primaryMuscle'] as String,
      equipment: json['equipment'] as String,
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Converts ExerciseDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryMuscle': primaryMuscle,
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description,
      primaryMuscle: primaryMuscle,
      equipment: equipment,
      secondaryMuscles: List.from(secondaryMuscles),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseDto &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.primaryMuscle == primaryMuscle &&
        other.equipment == equipment &&
        _listEquals(other.secondaryMuscles, secondaryMuscles);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      primaryMuscle,
      equipment,
      secondaryMuscles.length,
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
    return 'ExerciseDto(id: $id, name: $name, primaryMuscle: $primaryMuscle, equipment: $equipment)';
  }
}
