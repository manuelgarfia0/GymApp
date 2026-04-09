import '../../core/di/core_dependencies.dart';
import '../../core/network/api_client.dart';
import '../../core/session/session_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../workouts/data/repositories/workout_repository_impl.dart';
import '../workouts/data/datasources/workout_remote_datasource.dart';
import 'data/datasources/profile_remote_datasource.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/repositories/user_stats_repository_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/use_cases/get_current_user_profile.dart';
import 'domain/use_cases/get_user_profile.dart';
import 'domain/use_cases/get_user_stats.dart';
import 'domain/use_cases/update_user_profile.dart';

class ProfileDependencies {
  static ProfileRemoteDatasource? _remoteDatasource;
  static ProfileRepository? _repository;
  static UserStatsRepository? _statsRepository;
  static GetCurrentUserProfile? _getCurrentUserProfileUseCase;
  static GetUserProfile? _getUserProfileUseCase;
  static UpdateUserProfile? _updateUserProfileUseCase;

  static ApiClient get apiClient => CoreDependencies.apiClient;
  static SecureStorageService get storageService =>
      CoreDependencies.storageService;
  static SessionService get sessionService => CoreDependencies.sessionService;

  static ProfileRemoteDatasource get remoteDatasource {
    _remoteDatasource ??= ProfileRemoteDatasourceImpl(apiClient);
    return _remoteDatasource!;
  }

  static ProfileRepository get repository {
    _repository ??= ProfileRepositoryImpl(
      remoteDatasource: remoteDatasource,
      sessionService: sessionService,
    );
    return _repository!;
  }

  static UserStatsRepository get statsRepository {
    _statsRepository ??= UserStatsRepositoryImpl(
      WorkoutRepositoryImpl(
        remoteDatasource: WorkoutRemoteDatasourceImpl(apiClient),
      ),
    );
    return _statsRepository!;
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
    _statsRepository = null;
    _getCurrentUserProfileUseCase = null;
    _getUserProfileUseCase = null;
    _updateUserProfileUseCase = null;
  }
}
