import '../../domain/entities/user.dart';

class UserDto {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final String? createdAt;
  final bool publicProfile;

  const UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
    this.publicProfile = true,
  });

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

  /// CORRECCIÓN: publicProfile ya se incluye en la entidad de dominio
  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      isPremium: isPremium,
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      publicProfile: publicProfile,
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
        other.publicProfile == publicProfile;
  }

  @override
  int get hashCode =>
      Object.hash(id, username, email, isPremium, publicProfile);

  @override
  String toString() =>
      'UserDto(id: $id, username: $username, email: $email, isPremium: $isPremium, publicProfile: $publicProfile)';
}
