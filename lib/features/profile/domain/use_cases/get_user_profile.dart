import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetUserProfile {
  final ProfileRepository repository;

  GetUserProfile(this.repository);

  /// Obtiene el perfil de usuario para el ID de usuario especificado
  Future<UserProfile?> call(int userId) async {
    return await repository.getUserProfile(userId);
  }
}
