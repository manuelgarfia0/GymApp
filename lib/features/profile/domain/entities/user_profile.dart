class UserProfile {
  final int userId;
  final String username;
  final String email;
  final bool isPremium;
  final bool publicProfile; // AÑADIDO
  final String? languagePreference;
  final DateTime? createdAt;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.isPremium,
    this.publicProfile = true, // AÑADIDO
    this.languagePreference,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.preferences = const {},
  });

  UserProfile copyWith({
    int? userId,
    String? username,
    String? email,
    bool? isPremium,
    bool? publicProfile, // AÑADIDO
    String? languagePreference,
    DateTime? createdAt,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      publicProfile: publicProfile ?? this.publicProfile, // AÑADIDO
      languagePreference: languagePreference ?? this.languagePreference,
      createdAt: createdAt ?? this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.userId == userId &&
        other.username == username &&
        other.email == email &&
        other.isPremium == isPremium &&
        other.publicProfile == publicProfile && // AÑADIDO
        other.languagePreference == languagePreference &&
        other.createdAt == createdAt &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.dateOfBirth == dateOfBirth;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        username.hashCode ^
        email.hashCode ^
        isPremium.hashCode ^
        publicProfile.hashCode ^ // AÑADIDO
        languagePreference.hashCode ^
        createdAt.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        dateOfBirth.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, email: $email, '
        'isPremium: $isPremium, publicProfile: $publicProfile)';
  }
}