class UserDTO {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final String? createdAt;

  UserDTO({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
  });

  // Método de fábrica para construir el objeto desde el JSON que nos envía Spring Boot
  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      // Mapeamos el boolean 'premium' que nos devuelve la API
      isPremium: json['premium'] ?? false,
      languagePreference: json['languagePreference'],
      createdAt: json['createdAt'],
    );
  }
}