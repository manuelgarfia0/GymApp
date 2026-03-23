import '../../core/di/core_dependencies.dart';
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

/// Factory de dependencias del feature de autenticación.
/// Usa [CoreDependencies] para obtener el ApiClient compartido,
/// evitando múltiples instancias del cliente HTTP en la app.
class AuthDependencies {
  static AuthRemoteDatasource? _remoteDatasource;
  static AuthRepository? _repository;
  static LoginUser? _loginUseCase;
  static RegisterUser? _registerUseCase;
  static LogoutUser? _logoutUseCase;
  static GetCurrentUser? _getCurrentUserUseCase;
  static CheckAuthStatus? _checkAuthStatusUseCase;

  /// ApiClient compartido con el resto de features.
  static ApiClient get apiClient => CoreDependencies.apiClient;

  /// SecureStorageService compartido con el resto de features.
  static SecureStorageService get storageService =>
      CoreDependencies.storageService;

  static AuthRemoteDatasource get remoteDatasource {
    _remoteDatasource ??= AuthRemoteDatasourceImpl(apiClient);
    return _remoteDatasource!;
  }

  static AuthRepository get repository {
    _repository ??= AuthRepositoryImpl(
      remoteDatasource: remoteDatasource,
      storageService: storageService,
    );
    return _repository!;
  }

  static LoginUser get loginUseCase {
    _loginUseCase ??= LoginUser(repository);
    return _loginUseCase!;
  }

  static RegisterUser get registerUseCase {
    _registerUseCase ??= RegisterUser(repository);
    return _registerUseCase!;
  }

  static LogoutUser get logoutUseCase {
    _logoutUseCase ??= LogoutUser(repository);
    return _logoutUseCase!;
  }

  static GetCurrentUser get getCurrentUserUseCase {
    _getCurrentUserUseCase ??= GetCurrentUser(repository);
    return _getCurrentUserUseCase!;
  }

  static CheckAuthStatus get checkAuthStatusUseCase {
    _checkAuthStatusUseCase ??= CheckAuthStatus(repository);
    return _checkAuthStatusUseCase!;
  }

  static void reset() {
    _remoteDatasource = null;
    _repository = null;
    _loginUseCase = null;
    _registerUseCase = null;
    _logoutUseCase = null;
    _getCurrentUserUseCase = null;
    _checkAuthStatusUseCase = null;
  }
}
