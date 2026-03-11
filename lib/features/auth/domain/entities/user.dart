// Domain entity for User - pure Dart, no Flutter dependencies
class User {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.isPremium == isPremium &&
        other.languagePreference == languagePreference &&
        other.createdAt == createdAt;
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
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, isPremium: $isPremium, languagePreference: $languagePreference, createdAt: $createdAt)';
  }
}
