import '../../domain/entities/user.dart';

/// Data Transfer Object for User
/// Handles JSON serialization/deserialization with the Spring Boot backend
class UserDto {
  final int id;
  final String username;
  final String email;
  final bool isPremium; // Cambiado de 'premium' a 'isPremium'
  final String? languagePreference;
  final String? createdAt;
  final bool publicProfile; // Agregado campo faltante

  const UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
    this.publicProfile = true,
  });

  /// Creates UserDto from JSON response from Spring Boot API
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      isPremium:
          json['isPremium'] as bool? ?? json['premium'] as bool? ?? false,
      languagePreference: json['languagePreference'] as String?,
      createdAt: json['createdAt'] as String?,
      publicProfile: json['publicProfile'] as bool? ?? true,
    );
  }

  /// Converts UserDto to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'isPremium': isPremium,
      'languagePreference': languagePreference,
      'createdAt': createdAt,
      'publicProfile': publicProfile,
    };
  }

  /// Converts DTO to domain entity
  /// This ensures clean separation between data and domain layers
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      isPremium: isPremium,
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDto &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.isPremium == isPremium &&
        other.languagePreference == languagePreference &&
        other.createdAt == createdAt &&
        other.publicProfile == publicProfile;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      email,
      isPremium,
      languagePreference,
      createdAt,
      publicProfile,
    );
  }

  @override
  String toString() {
    return 'UserDto(id: $id, username: $username, email: $email, isPremium: $isPremium, languagePreference: $languagePreference, createdAt: $createdAt, publicProfile: $publicProfile)';
  }
}
