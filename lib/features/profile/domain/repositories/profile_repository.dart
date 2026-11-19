import '../entities/user_profile.dart';

abstract class ProfileRepository {
  /// Obtiene el perfil de usuario para el ID de usuario dado
  Future<UserProfile?> getUserProfile(int userId);

  /// Actualiza el perfil de usuario con los datos proporcionados
  Future<UserProfile> updateUserProfile(UserProfile userProfile);

  /// Obtiene el perfil del usuario actualmente autenticado
  Future<UserProfile?> getCurrentUserProfile();

  /// Cambia la contraseña del usuario validando la contraseña actual
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  );

  /// Elimina definitivamente la cuenta del usuario previa confirmación de contraseña
  Future<void> deleteAccount(int userId, String password);
}
