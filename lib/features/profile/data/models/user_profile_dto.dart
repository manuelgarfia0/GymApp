import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  final int? id; // Cambiado a nullable - no enmascarar con fallback
  final String? username; // Cambiado a nullable - no enmascarar con fallback
  final String? email; // Cambiado a nullable - no enmascarar con fallback
  final bool isPremium; // Estandarizado naming: isPremium consistentemente
  final String? languagePreference;
  final String? createdAt;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final Map<String, dynamic>? preferences;

  UserProfileDto({
    this.id, // Cambiado a opcional
    this.username, // Cambiado a opcional
    this.email, // Cambiado a opcional
    required this.isPremium, // Estandarizado naming
    this.languagePreference,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.preferences,
  });

  /// Constructor factory para crear UserProfileDto desde JSON
  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as int?, // Sin fallback - preserva valores nulos legítimos
      username:
          json['username']
              as String?, // Sin fallback - preserva valores nulos legítimos
      email:
          json['email']
              as String?, // Sin fallback - preserva valores nulos legítimos
      isPremium:
          json['isPremium'] as bool? ??
          json['premium'] as bool? ??
          false, // Maneja ambos nombres de campo
      languagePreference: json['languagePreference'] as String?,
      createdAt: json['createdAt'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
    );
  }

  /// Convierte a JSON para peticiones API
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      'isPremium': isPremium, // Usa naming estandarizado
      if (languagePreference != null) 'languagePreference': languagePreference,
      if (createdAt != null) 'createdAt': createdAt,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (preferences != null) 'preferences': preferences,
    };
  }

  /// Convierte DTO a entidad del dominio
  UserProfile toEntity() {
    return UserProfile(
      userId:
          id ??
          0, // Fallback solo en conversión a entidad, no en deserialización
      username: username ?? '', // Fallback solo en conversión a entidad
      email: email ?? '', // Fallback solo en conversión a entidad
      isPremium: isPremium,
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      preferences: preferences ?? {},
    );
  }

  /// Crea DTO desde entidad del dominio
  factory UserProfileDto.fromEntity(UserProfile entity) {
    return UserProfileDto(
      id: entity.userId,
      username: entity.username,
      email: entity.email,
      isPremium: entity.isPremium,
      languagePreference: entity.languagePreference,
      createdAt: entity.createdAt?.toIso8601String(),
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: entity.dateOfBirth?.toIso8601String(),
      preferences: entity.preferences,
    );
  }
}
