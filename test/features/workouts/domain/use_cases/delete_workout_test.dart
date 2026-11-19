import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workouts/domain/repositories/workout_repository.dart';
import 'package:gym_app/features/workouts/domain/use_cases/delete_workout.dart';

class _FakeWorkoutRepository extends Fake implements WorkoutRepository {
  bool resultToReturn = true;
  Object? errorToThrow;
  int? lastDeletedId;

  @override
  Future<bool> deleteWorkout(int id) async {
    lastDeletedId = id;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return resultToReturn;
  }
}

void main() {
  group('DeleteWorkout', () {
    late _FakeWorkoutRepository repository;
    late DeleteWorkout useCase;

    setUp(() {
      repository = _FakeWorkoutRepository();
      useCase = DeleteWorkout(repository);
    });

    test('throws Exception when workout id is <= 0', () async {
      await expectLater(useCase(0), throwsA(isA<Exception>()));
      await expectLater(useCase(-5), throwsA(isA<Exception>()));
      expect(repository.lastDeletedId, isNull);
    });

    test('delegates valid workout id to repository and returns result', () async {
      repository.resultToReturn = true;

      final result = await useCase(42);

      expect(result, isTrue);
      expect(repository.lastDeletedId, 42);
    });

    test('propagates repository errors', () async {
      repository.errorToThrow = Exception('Delete failed');

      await expectLater(useCase(7), throwsA(isA<Exception>()));
      expect(repository.lastDeletedId, 7);
    });
  });
}
