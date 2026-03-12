import '../../domain/entities/exercise.dart';

/// Data Transfer Object para Exercise
/// Maneja la serialización/deserialización JSON con el backend Spring Boot
class ExerciseDto {
  final int id;
  final String name;
  final String?
  description; // Cambiado a nullable para manejar valores nulos del backend
  final String?
  primaryMuscle; // Cambiado a nullable para manejar valores nulos del backend
  final String equipment;
  final List<String> secondaryMuscles;

  const ExerciseDto({
    required this.id,
    required this.name,
    this.description, // Cambiado a opcional para manejar valores nulos
    this.primaryMuscle, // Cambiado a opcional para manejar valores nulos
    required this.equipment,
    required this.secondaryMuscles,
  });

  /// Crea ExerciseDto desde respuesta JSON de la API Spring Boot
  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    return ExerciseDto(
      id: json['id'] as int,
      name: json['name'] as String,
      description:
          json['description'] as String?, // Maneja valores nulos apropiadamente
      primaryMuscle:
          json['primaryMuscle']
              as String?, // Maneja valores nulos apropiadamente
      equipment: json['equipment'] as String,
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Convierte ExerciseDto a JSON para peticiones API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null)
        'description': description, // Solo incluye si no es nulo
      if (primaryMuscle != null)
        'primaryMuscle': primaryMuscle, // Solo incluye si no es nulo
      'equipment': equipment,
      'secondaryMuscles': secondaryMuscles,
    };
  }

  /// Convierte DTO a entidad del dominio
  /// Esto asegura separación limpia entre capas de datos y dominio
  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description, // Pasa el valor nulo si existe
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
