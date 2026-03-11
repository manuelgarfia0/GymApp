import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateUserProfile {
  final ProfileRepository repository;

  UpdateUserProfile(this.repository);

  /// Actualiza el perfil de usuario con los datos proporcionados
  Future<UserProfile> call(UserProfile userProfile) async {
    return await repository.updateUserProfile(userProfile);
  }
}
