class UserProfile {
  final int userId;
  final String username;
  final String email;
  final bool isPremium;
  final bool publicProfile;
  final bool showDateOfBirth;
  final bool showGlobalStats;
  final bool showPublicRoutines;
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
    this.publicProfile = true,
    this.showDateOfBirth = true,
    this.showGlobalStats = true,
    this.showPublicRoutines = true,
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
    bool? publicProfile,
    bool? showDateOfBirth,
    bool? showGlobalStats,
    bool? showPublicRoutines,
    String? languagePreference,
    DateTime? createdAt,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      isPremium: isPremium ?? this.isPremium,
      publicProfile: publicProfile ?? this.publicProfile,
      showDateOfBirth: showDateOfBirth ?? this.showDateOfBirth,
      showGlobalStats: showGlobalStats ?? this.showGlobalStats,
      showPublicRoutines: showPublicRoutines ?? this.showPublicRoutines,
      languagePreference: languagePreference ?? this.languagePreference,
      createdAt: createdAt ?? this.createdAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
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
        other.publicProfile == publicProfile &&
        other.showDateOfBirth == showDateOfBirth &&
        other.showGlobalStats == showGlobalStats &&
        other.showPublicRoutines == showPublicRoutines &&
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
        publicProfile.hashCode ^
        showDateOfBirth.hashCode ^
        showGlobalStats.hashCode ^
        showPublicRoutines.hashCode ^
        languagePreference.hashCode ^
        createdAt.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        dateOfBirth.hashCode;
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, username: $username, email: $email, '
        'isPremium: $isPremium, publicProfile: $publicProfile, '
        'showDateOfBirth: $showDateOfBirth, showGlobalStats: $showGlobalStats, '
        'showPublicRoutines: $showPublicRoutines)';
  }
}
