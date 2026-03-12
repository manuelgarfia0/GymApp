import '../../domain/entities/exercise.dart';

/// Data Transfer Object para Exercise
/// Maneja la serialización/deserialización JSON con el backend Spring Boot
class ExerciseDto {
  final int id;
  final String name;
  final String? description;
  final String?
  category; // Mapea equipment o category del backend con estrategia de fallback robusta
  final String? primaryMuscle; // Opcional ya que el backend no lo envía
  final List<String> secondaryMuscles; // Opcional ya que el backend no lo envía

  const ExerciseDto({
    required this.id,
    required this.name,
    this.description,
    this.category, // Mapea equipment o category del backend con validación
    this.primaryMuscle,
    required this.secondaryMuscles,
  });

  /// Crea ExerciseDto desde respuesta JSON de la API Spring Boot
  ///
  /// Implementa estrategia de mapeo robusto para el campo equipment/category:
  /// - Si el backend envía "equipment": mapea json['equipment'] a category property
  /// - Si el backend envía "category": mapea json['category'] a category property
  /// - Implementa validación para manejar campos faltantes o nulos gracefully
  /// - Asegura compatibilidad con diferentes versiones de la API Spring Boot
  factory ExerciseDto.fromJson(Map<String, dynamic> json) {
    // Estrategia de fallback mejorada para mapeo de campo equipment/category
    // Prioridad: 'equipment' -> 'category' -> null (manejo graceful)
    // Validación adicional para detectar y manejar datos malformados
    String? equipmentValue;

    // Intenta mapear 'equipment' primero (campo preferido del backend)
    if (json.containsKey('equipment')) {
      final rawEquipment = json['equipment'];
      if (rawEquipment != null &&
          rawEquipment is String &&
          rawEquipment.trim().isNotEmpty) {
        equipmentValue = rawEquipment.trim();
      }
    }

    // Fallback a 'category' si 'equipment' no está disponible o es inválido
    if (equipmentValue == null && json.containsKey('category')) {
      final rawCategory = json['category'];
      if (rawCategory != null &&
          rawCategory is String &&
          rawCategory.trim().isNotEmpty) {
        equipmentValue = rawCategory.trim();
      }
    }

    return ExerciseDto(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Exercise',
      description: json['description'] as String?,
      category:
          equipmentValue, // Campo equipment/category mapeado con validación robusta
      primaryMuscle: json['primaryMuscle'] as String?, // Opcional
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e as String?)
              .where((e) => e != null && e.trim().isNotEmpty)
              .cast<String>()
              .toList() ??
          [], // Lista vacía si no existe o contiene valores inválidos
    );
  }

  /// Convierte ExerciseDto a JSON para peticiones API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (category != null)
        'category':
            category, // Envía como category para compatibilidad con backend
      if (primaryMuscle != null) 'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
    };
  }

  /// Convierte DTO a entidad del dominio
  /// Esto asegura separación limpia entre capas de datos y dominio
  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description,
      category:
          category, // Campo equipment/category mapeado con estrategia de fallback
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
        other.primaryMuscle == primaryMuscle &&
        _listEquals(other.secondaryMuscles, secondaryMuscles);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      category,
      primaryMuscle,
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
    return 'ExerciseDto(id: $id, name: $name, category: $category, primaryMuscle: $primaryMuscle)';
  }
}
