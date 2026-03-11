import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/use_cases/get_current_user_profile.dart';
import 'domain/use_cases/get_user_profile.dart';
import 'domain/use_cases/update_user_profile.dart';

/// Clase factory para crear dependencias de profile
/// Proporciona instancias correctamente configuradas siguiendo principios de Clean Architecture
class ProfileDependencies {
  static ApiClient? _apiClient;
  static SecureStorageService? _storageService;
  static ProfileRemoteDatasource? _remoteDatasource;
  static ProfileRepository? _repository;
  static GetCurrentUserProfile? _getCurrentUserProfileUseCase;
  static GetUserProfile? _getUserProfileUseCase;
  static UpdateUserProfile? _updateUserProfileUseCase;

  /// Obtener o crear instancia de ApiClient
  static ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }

  /// Obtener o crear instancia de SecureStorageService
  static SecureStorageService get storageService {
    _storageService ??= SecureStorageService();
    return _storageService!;
  }

  /// Obtener o crear instancia de ProfileRemoteDatasource
  static ProfileRemoteDatasource get remoteDatasource {
    _remoteDatasource ??= ProfileRemoteDatasourceImpl(apiClient);
    return _remoteDatasource!;
  }

  /// Get or create ProfileRepository instance
  static ProfileRepository get repository {
    _repository ??= ProfileRepositoryImpl(remoteDatasource);
    return _repository!;
  }

  /// Get or create GetCurrentUserProfile use case instance
  static GetCurrentUserProfile get getCurrentUserProfileUseCase {
    _getCurrentUserProfileUseCase ??= GetCurrentUserProfile(repository);
    return _getCurrentUserProfileUseCase!;
  }

  /// Get or create GetUserProfile use case instance
  static GetUserProfile get getUserProfileUseCase {
    _getUserProfileUseCase ??= GetUserProfile(repository);
    return _getUserProfileUseCase!;
  }

  /// Get or create UpdateUserProfile use case instance
  static UpdateUserProfile get updateUserProfileUseCase {
    _updateUserProfileUseCase ??= UpdateUserProfile(repository);
    return _updateUserProfileUseCase!;
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    _apiClient = null;
    _storageService = null;
    _remoteDatasource = null;
    _repository = null;
    _getCurrentUserProfileUseCase = null;
    _getUserProfileUseCase = null;
    _updateUserProfileUseCase = null;
  }
}
