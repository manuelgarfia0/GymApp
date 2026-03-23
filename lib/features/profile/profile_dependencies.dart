import '../../core/di/core_dependencies.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/use_cases/get_current_user_profile.dart';
import 'domain/use_cases/get_user_profile.dart';
import 'domain/use_cases/update_user_profile.dart';

/// Factory de dependencias del feature de perfil.
/// Usa [CoreDependencies] para el ApiClient y SecureStorageService compartidos.
class ProfileDependencies {
  static ProfileRemoteDatasource? _remoteDatasource;
  static ProfileRepository? _repository;
  static GetCurrentUserProfile? _getCurrentUserProfileUseCase;
  static GetUserProfile? _getUserProfileUseCase;
  static UpdateUserProfile? _updateUserProfileUseCase;

  static ApiClient get apiClient => CoreDependencies.apiClient;
  static SecureStorageService get storageService =>
      CoreDependencies.storageService;

  static ProfileRemoteDatasource get remoteDatasource {
    _remoteDatasource ??= ProfileRemoteDatasourceImpl(apiClient);
    return _remoteDatasource!;
  }

  static ProfileRepository get repository {
    _repository ??= ProfileRepositoryImpl(remoteDatasource);
    return _repository!;
  }

  static GetCurrentUserProfile get getCurrentUserProfileUseCase {
    _getCurrentUserProfileUseCase ??= GetCurrentUserProfile(repository);
    return _getCurrentUserProfileUseCase!;
  }

  static GetUserProfile get getUserProfileUseCase {
    _getUserProfileUseCase ??= GetUserProfile(repository);
    return _getUserProfileUseCase!;
  }

  static UpdateUserProfile get updateUserProfileUseCase {
    _updateUserProfileUseCase ??= UpdateUserProfile(repository);
    return _updateUserProfileUseCase!;
  }

  static void reset() {
    _remoteDatasource = null;
    _repository = null;
    _getCurrentUserProfileUseCase = null;
    _getUserProfileUseCase = null;
    _updateUserProfileUseCase = null;
  }
}
