import '../entities/user_profile.dart';

abstract class ProfileRepository {
  /// Obtiene el perfil de usuario para el ID de usuario dado
  Future<UserProfile?> getUserProfile(int userId);

  /// Actualiza el perfil de usuario con los datos proporcionados
  Future<UserProfile> updateUserProfile(UserProfile userProfile);

  /// Obtiene el perfil del usuario actualmente autenticado
  Future<UserProfile?> getCurrentUserProfile();
}
