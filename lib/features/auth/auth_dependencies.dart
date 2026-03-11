import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/use_cases/check_auth_status.dart';
import 'domain/use_cases/get_current_user.dart';
import 'domain/use_cases/login_user.dart';
import 'domain/use_cases/logout_user.dart';
import 'domain/use_cases/register_user.dart';

/// Factory class for creating authentication dependencies
/// Provides properly wired instances following clean architecture principles
class AuthDependencies {
  static ApiClient? _apiClient;
  static SecureStorageService? _storageService;
  static AuthRemoteDatasource? _remoteDatasource;
  static AuthRepository? _repository;
  static LoginUser? _loginUseCase;
  static RegisterUser? _registerUseCase;
  static LogoutUser? _logoutUseCase;
  static GetCurrentUser? _getCurrentUserUseCase;
  static CheckAuthStatus? _checkAuthStatusUseCase;

  /// Get or create ApiClient instance
  static ApiClient get apiClient {
    _apiClient ??= ApiClient();
    return _apiClient!;
  }

  /// Get or create SecureStorageService instance
  static SecureStorageService get storageService {
    _storageService ??= SecureStorageService();
    return _storageService!;
  }

  /// Get or create AuthRemoteDatasource instance
  static AuthRemoteDatasource get remoteDatasource {
    _remoteDatasource ??= AuthRemoteDatasourceImpl(apiClient);
    return _remoteDatasource!;
  }

  /// Get or create AuthRepository instance
  static AuthRepository get repository {
    _repository ??= AuthRepositoryImpl(
      remoteDatasource: remoteDatasource,
      storageService: storageService,
    );
    return _repository!;
  }

  /// Get or create LoginUser use case instance
  static LoginUser get loginUseCase {
    _loginUseCase ??= LoginUser(repository);
    return _loginUseCase!;
  }

  /// Get or create RegisterUser use case instance
  static RegisterUser get registerUseCase {
    _registerUseCase ??= RegisterUser(repository);
    return _registerUseCase!;
  }

  /// Get or create LogoutUser use case instance
  static LogoutUser get logoutUseCase {
    _logoutUseCase ??= LogoutUser(repository);
    return _logoutUseCase!;
  }

  /// Get or create GetCurrentUser use case instance
  static GetCurrentUser get getCurrentUserUseCase {
    _getCurrentUserUseCase ??= GetCurrentUser(repository);
    return _getCurrentUserUseCase!;
  }

  /// Get or create CheckAuthStatus use case instance
  static CheckAuthStatus get checkAuthStatusUseCase {
    _checkAuthStatusUseCase ??= CheckAuthStatus(repository);
    return _checkAuthStatusUseCase!;
  }

  /// Reset all dependencies (useful for testing)
  static void reset() {
    _apiClient = null;
    _storageService = null;
    _remoteDatasource = null;
    _repository = null;
    _loginUseCase = null;
    _registerUseCase = null;
    _logoutUseCase = null;
    _getCurrentUserUseCase = null;
    _checkAuthStatusUseCase = null;
  }
}
