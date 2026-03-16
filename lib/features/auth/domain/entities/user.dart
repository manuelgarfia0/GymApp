/// Entidad de dominio para User.
class User {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final DateTime? createdAt;
  // AÑADIDO: el backend envía este campo y es relevante para la lógica de acceso
  final bool publicProfile;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
    this.publicProfile = true,
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
        other.createdAt == createdAt &&
        other.publicProfile == publicProfile;
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    email,
    isPremium,
    languagePreference,
    createdAt,
    publicProfile,
  );

  @override
  String toString() =>
      'User(id: $id, username: $username, email: $email, isPremium: $isPremium, publicProfile: $publicProfile)';
}
