import '../../domain/entities/exercise.dart';

/// Data Transfer Object para Exercise
/// Los nombres de campos coinciden exactamente con lo que devuelve el backend Spring Boot:
///   - "primaryMuscleName"   (no "primaryMuscle")
///   - "equipmentName"       (no "equipment" ni "category")
///   - "secondaryMuscleNames" (no "secondaryMuscles")
class ExerciseDto {
  final int id;
  final String name;
  final String? description;
  final String? primaryMuscle;
  final String? category; // viene de "equipmentName" en el backend
  final List<String> secondaryMuscles;

  const ExerciseDto({
    required this.id,
    required this.name,
    this.description,
    this.primaryMuscle,
    this.category,
    required this.secondaryMuscles,
  });

  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    return ExerciseDto(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Exercise',
      description: json['description'] as String?,

      // El backend envía "primaryMuscleName", no "primaryMuscle"
      primaryMuscle: json['primaryMuscleName'] as String?,

      // El backend envía "equipmentName", no "equipment" ni "category"
      // Fallbacks por si cambia el contrato: equipment -> category -> null
      category:
          json['equipmentName'] as String? ??
          json['equipment'] as String? ??
          json['category'] as String?,

      // El backend envía "secondaryMuscleNames", no "secondaryMuscles"
      secondaryMuscles:
          (json['secondaryMuscleNames'] as List<dynamic>?)
              ?.whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (primaryMuscle != null) 'primaryMuscleName': primaryMuscle,
      if (category != null) 'equipmentName': category,
      'secondaryMuscleNames': secondaryMuscles,
    };
  }

  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description,
      category: category,
      primaryMuscle: primaryMuscle,
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
        other.category == category &&
        other.primaryMuscle == primaryMuscle;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, category, primaryMuscle);

  @override
  String toString() =>
      'ExerciseDto(id: $id, name: $name, category: $category, primaryMuscle: $primaryMuscle)';
}
