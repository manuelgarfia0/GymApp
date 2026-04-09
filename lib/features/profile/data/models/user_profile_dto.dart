import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  final int? id;
  final String? username;
  final String? email;
  final bool isPremium;
  final bool publicProfile; // AÑADIDO
  final String? languagePreference;
  final String? createdAt;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final Map<String, dynamic>? preferences;

  UserProfileDto({
    this.id,
    this.username,
    this.email,
    required this.isPremium,
    this.publicProfile = true, // AÑADIDO
    this.languagePreference,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.preferences,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as int?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isPremium: json['isPremium'] as bool? ?? json['premium'] as bool? ?? false,
      publicProfile: json['publicProfile'] as bool? ?? true, // AÑADIDO
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      'isPremium': isPremium,
      'publicProfile': publicProfile, // AÑADIDO
      if (languagePreference != null) 'languagePreference': languagePreference,
      if (createdAt != null) 'createdAt': createdAt,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (preferences != null) 'preferences': preferences,
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      userId: id ?? 0,
      username: username ?? '',
      email: email ?? '',
      isPremium: isPremium,
      publicProfile: publicProfile, // AÑADIDO
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      preferences: preferences ?? {},
    );
  }

  factory UserProfileDto.fromEntity(UserProfile entity) {
    return UserProfileDto(
      id: entity.userId,
      username: entity.username,
      email: entity.email,
      isPremium: entity.isPremium,
      publicProfile: entity.publicProfile, // AÑADIDO
      languagePreference: entity.languagePreference,
      createdAt: entity.createdAt?.toIso8601String(),
      firstName: entity.firstName,
      lastName: entity.lastName,
      dateOfBirth: entity.dateOfBirth?.toIso8601String(),
      preferences: entity.preferences,
    );
  }
}