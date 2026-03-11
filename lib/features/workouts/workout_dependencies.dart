import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'data/datasources/exercise_remote_datasource.dart';
import 'data/datasources/routine_remote_datasource.dart';
import 'data/datasources/workout_remote_datasource.dart';
import 'data/repositories/exercise_repository_impl.dart';
import 'data/repositories/routine_repository_impl.dart';
import 'data/repositories/workout_repository_impl.dart';
import 'domain/repositories/exercise_repository.dart';
import 'domain/repositories/routine_repository.dart';
import 'domain/repositories/workout_repository.dart';
import 'domain/use_cases/create_routine.dart';
import 'domain/use_cases/get_exercises.dart';
import 'domain/use_cases/get_routines.dart';
import 'domain/use_cases/get_workout_history.dart';
import 'domain/use_cases/log_exercise.dart';
import 'domain/use_cases/save_workout.dart';
import 'domain/use_cases/start_workout.dart';

/// Clase factory para crear dependencias de workouts
/// Proporciona instancias correctamente configuradas siguiendo principios de Clean Architecture
class WorkoutDependencies {
  static ApiClient? _apiClient;
  static SecureStorageService? _storageService;

  // Datasources
  static ExerciseRemoteDatasource? _exerciseRemoteDatasource;
  static RoutineRemoteDatasource? _routineRemoteDatasource;
  static WorkoutRemoteDatasource? _workoutRemoteDatasource;

  // Repositories
  static ExerciseRepository? _exerciseRepository;
  static RoutineRepository? _routineRepository;
  static WorkoutRepository? _workoutRepository;

  // Use Cases
  static CreateRoutine? _createRoutineUseCase;
  static GetExercises? _getExercisesUseCase;
  static GetRoutines? _getRoutinesUseCase;
  static GetWorkoutHistory? _getWorkoutHistoryUseCase;
  static LogExercise? _logExerciseUseCase;
  static SaveWorkout? _saveWorkoutUseCase;
  static StartWorkout? _startWorkoutUseCase;

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

  // Getters de Datasources

  /// Obtener o crear instancia de ExerciseRemoteDatasource
  static ExerciseRemoteDatasource get exerciseRemoteDatasource {
    _exerciseRemoteDatasource ??= ExerciseRemoteDatasourceImpl(apiClient);
    return _exerciseRemoteDatasource!;
  }

  /// Obtener o crear instancia de RoutineRemoteDatasource
  static RoutineRemoteDatasource get routineRemoteDatasource {
    _routineRemoteDatasource ??= RoutineRemoteDatasourceImpl(apiClient);
    return _routineRemoteDatasource!;
  }

  /// Obtener o crear instancia de WorkoutRemoteDatasource
  static WorkoutRemoteDatasource get workoutRemoteDatasource {
    _workoutRemoteDatasource ??= WorkoutRemoteDatasourceImpl(apiClient);
    return _workoutRemoteDatasource!;
  }

  // Getters de Repositories

  /// Obtener o crear instancia de ExerciseRepository
  static ExerciseRepository get exerciseRepository {
    _exerciseRepository ??= ExerciseRepositoryImpl(
      remoteDatasource: exerciseRemoteDatasource,
    );
    return _exerciseRepository!;
  }

  /// Obtener o crear instancia de RoutineRepository
  static RoutineRepository get routineRepository {
    _routineRepository ??= RoutineRepositoryImpl(
      remoteDatasource: routineRemoteDatasource,
    );
    return _routineRepository!;
  }

  /// Obtener o crear instancia de WorkoutRepository
  static WorkoutRepository get workoutRepository {
    _workoutRepository ??= WorkoutRepositoryImpl(
      remoteDatasource: workoutRemoteDatasource,
    );
    return _workoutRepository!;
  }

  // Getters de Use Cases

  /// Obtener o crear instancia del use case CreateRoutine
  static CreateRoutine get createRoutineUseCase {
    _createRoutineUseCase ??= CreateRoutine(routineRepository);
    return _createRoutineUseCase!;
  }

  /// Obtener o crear instancia del use case GetExercises
  static GetExercises get getExercisesUseCase {
    _getExercisesUseCase ??= GetExercises(exerciseRepository);
    return _getExercisesUseCase!;
  }

  /// Obtener o crear instancia del use case GetRoutines
  static GetRoutines get getRoutinesUseCase {
    _getRoutinesUseCase ??= GetRoutines(routineRepository);
    return _getRoutinesUseCase!;
  }

  /// Obtener o crear instancia del use case GetWorkoutHistory
  static GetWorkoutHistory get getWorkoutHistoryUseCase {
    _getWorkoutHistoryUseCase ??= GetWorkoutHistory(workoutRepository);
    return _getWorkoutHistoryUseCase!;
  }

  /// Obtener o crear instancia del use case LogExercise
  static LogExercise get logExerciseUseCase {
    _logExerciseUseCase ??= LogExercise(workoutRepository);
    return _logExerciseUseCase!;
  }

  /// Obtener o crear instancia del use case SaveWorkout
  static SaveWorkout get saveWorkoutUseCase {
    _saveWorkoutUseCase ??= SaveWorkout(workoutRepository);
    return _saveWorkoutUseCase!;
  }

  /// Obtener o crear instancia del use case StartWorkout
  static StartWorkout get startWorkoutUseCase {
    _startWorkoutUseCase ??= StartWorkout(workoutRepository, routineRepository);
    return _startWorkoutUseCase!;
  }

  /// Reiniciar todas las dependencias (útil para testing)
  static void reset() {
    _apiClient = null;
    _storageService = null;
    _exerciseRemoteDatasource = null;
    _routineRemoteDatasource = null;
    _workoutRemoteDatasource = null;
    _exerciseRepository = null;
    _routineRepository = null;
    _workoutRepository = null;
    _createRoutineUseCase = null;
    _getExercisesUseCase = null;
    _getRoutinesUseCase = null;
    _getWorkoutHistoryUseCase = null;
    _logExerciseUseCase = null;
    _saveWorkoutUseCase = null;
    _startWorkoutUseCase = null;
  }
}
