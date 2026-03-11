import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetCurrentUserProfile {
  final ProfileRepository repository;

  GetCurrentUserProfile(this.repository);

  /// Obtiene el perfil del usuario actualmente autenticado
  Future<UserProfile?> call() async {
    return await repository.getCurrentUserProfile();
  }
}
