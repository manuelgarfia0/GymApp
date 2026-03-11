import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  final int id;
  final String username;
  final String email;
  final bool premium;
  final String? languagePreference;
  final String? createdAt;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final Map<String, dynamic>? preferences;

  UserProfileDto({
    required this.id,
    required this.username,
    required this.email,
    required this.premium,
    this.languagePreference,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.preferences,
  });

  /// Factory constructor to create UserProfileDto from JSON
  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      premium: json['premium'] ?? false,
      languagePreference: json['languagePreference'],
      createdAt: json['createdAt'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      dateOfBirth: json['dateOfBirth'],
      preferences: json['preferences'] != null
          ? Map<String, dynamic>.from(json['preferences'])
          : null,
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'premium': premium,
      'languagePreference': languagePreference,
      'createdAt': createdAt,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'preferences': preferences,
    };
  }

  /// Convert DTO to domain entity
  UserProfile toEntity() {
    return UserProfile(
      userId: id,
      username: username,
      email: email,
      isPremium: premium,
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      preferences: preferences ?? {},
    );
  }

  /// Create DTO from domain entity
  factory UserProfileDto.fromEntity(UserProfile entity) {
    return UserProfileDto(
      id: entity.userId,
      username: entity.username,
      email: entity.email,
      premium: entity.isPremium,
      languagePreference: entity.languagePreference,
      createdAt: entity.createdAt?.toIso8601String(),
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: entity.dateOfBirth?.toIso8601String(),
      preferences: entity.preferences,
    );
  }
}
