import '../../core/di/core_dependencies.dart';
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
import 'domain/use_cases/delete_routine.dart';   // NUEVO
import 'domain/use_cases/get_exercises.dart';
import 'domain/use_cases/get_routines.dart';
import 'domain/use_cases/get_workout_history.dart';
import 'domain/use_cases/log_exercise.dart';
import 'domain/use_cases/save_workout.dart';
import 'domain/use_cases/start_workout.dart';
import 'domain/use_cases/update_routine.dart';   // NUEVO

class WorkoutDependencies {
  static SecureStorageService get storageService =>
      CoreDependencies.storageService;
  static ApiClient get apiClient => CoreDependencies.apiClient;

  static ExerciseRemoteDatasource? _exerciseRemoteDatasource;
  static RoutineRemoteDatasource? _routineRemoteDatasource;
  static WorkoutRemoteDatasource? _workoutRemoteDatasource;

  static ExerciseRepository? _exerciseRepository;
  static RoutineRepository? _routineRepository;
  static WorkoutRepository? _workoutRepository;

  static CreateRoutine? _createRoutineUseCase;
  static DeleteRoutine? _deleteRoutineUseCase;   // NUEVO
  static UpdateRoutine? _updateRoutineUseCase;   // NUEVO
  static GetExercises? _getExercisesUseCase;
  static GetRoutines? _getRoutinesUseCase;
  static GetWorkoutHistory? _getWorkoutHistoryUseCase;
  static LogExercise? _logExerciseUseCase;
  static SaveWorkout? _saveWorkoutUseCase;
  static StartWorkout? _startWorkoutUseCase;

  static ExerciseRemoteDatasource get exerciseRemoteDatasource {
    _exerciseRemoteDatasource ??= ExerciseRemoteDatasourceImpl(apiClient);
    return _exerciseRemoteDatasource!;
  }

  static RoutineRemoteDatasource get routineRemoteDatasource {
    _routineRemoteDatasource ??= RoutineRemoteDatasourceImpl(apiClient);
    return _routineRemoteDatasource!;
  }

  static WorkoutRemoteDatasource get workoutRemoteDatasource {
    _workoutRemoteDatasource ??= WorkoutRemoteDatasourceImpl(apiClient);
    return _workoutRemoteDatasource!;
  }

  static ExerciseRepository get exerciseRepository {
    _exerciseRepository ??= ExerciseRepositoryImpl(
      remoteDatasource: exerciseRemoteDatasource,
    );
    return _exerciseRepository!;
  }

  static RoutineRepository get routineRepository {
    _routineRepository ??= RoutineRepositoryImpl(
      remoteDatasource: routineRemoteDatasource,
    );
    return _routineRepository!;
  }

  static WorkoutRepository get workoutRepository {
    _workoutRepository ??= WorkoutRepositoryImpl(
      remoteDatasource: workoutRemoteDatasource,
    );
    return _workoutRepository!;
  }

  static CreateRoutine get createRoutineUseCase {
    _createRoutineUseCase ??= CreateRoutine(routineRepository);
    return _createRoutineUseCase!;
  }

  // NUEVO
  static DeleteRoutine get deleteRoutineUseCase {
    _deleteRoutineUseCase ??= DeleteRoutine(routineRepository);
    return _deleteRoutineUseCase!;
  }

  // NUEVO
  static UpdateRoutine get updateRoutineUseCase {
    _updateRoutineUseCase ??= UpdateRoutine(routineRepository);
    return _updateRoutineUseCase!;
  }

  static GetExercises get getExercisesUseCase {
    _getExercisesUseCase ??= GetExercises(exerciseRepository);
    return _getExercisesUseCase!;
  }

  static GetRoutines get getRoutinesUseCase {
    _getRoutinesUseCase ??= GetRoutines(routineRepository);
    return _getRoutinesUseCase!;
  }

  static GetWorkoutHistory get getWorkoutHistoryUseCase {
    _getWorkoutHistoryUseCase ??= GetWorkoutHistory(workoutRepository);
    return _getWorkoutHistoryUseCase!;
  }

  static LogExercise get logExerciseUseCase {
    _logExerciseUseCase ??= LogExercise(workoutRepository);
    return _logExerciseUseCase!;
  }

  static SaveWorkout get saveWorkoutUseCase {
    _saveWorkoutUseCase ??= SaveWorkout(workoutRepository);
    return _saveWorkoutUseCase!;
  }

  static StartWorkout get startWorkoutUseCase {
    _startWorkoutUseCase ??= StartWorkout(workoutRepository, routineRepository);
    return _startWorkoutUseCase!;
  }

  static void reset() {
    _exerciseRemoteDatasource = null;
    _routineRemoteDatasource = null;
    _workoutRemoteDatasource = null;
    _exerciseRepository = null;
    _routineRepository = null;
    _workoutRepository = null;
    _createRoutineUseCase = null;
    _deleteRoutineUseCase = null;   // NUEVO
    _updateRoutineUseCase = null;   // NUEVO
    _getExercisesUseCase = null;
    _getRoutinesUseCase = null;
    _getWorkoutHistoryUseCase = null;
    _logExerciseUseCase = null;
    _saveWorkoutUseCase = null;
    _startWorkoutUseCase = null;
  }
}