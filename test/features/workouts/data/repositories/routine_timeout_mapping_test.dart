import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/errors/failures.dart';
import 'package:gym_app/features/workouts/data/datasources/routine_remote_datasource.dart';
import 'package:gym_app/features/workouts/data/models/routine_dto.dart';
import 'package:gym_app/features/workouts/data/repositories/routine_repository_impl.dart';

class _TimeoutRoutineDatasource implements RoutineRemoteDatasource {
  @override
  Future<RoutineDto> createRoutine(RoutineDto routine) {
    throw TimeoutException('Future not completed');
  }

  @override
  Future<bool> deleteRoutine(int id) {
    throw TimeoutException('Future not completed');
  }

  @override
  Future<RoutineDto?> getRoutineById(int id) {
    throw TimeoutException('Future not completed');
  }

  @override
  Future<List<RoutineDto>> getUserRoutines(int userId) {
    throw TimeoutException('Future not completed');
  }

  @override
  Future<RoutineDto> updateRoutine(RoutineDto routine) {
    throw TimeoutException('Future not completed');
  }
}

void main() {
  group('RoutineRepositoryImpl timeout mapping', () {
    final repository = RoutineRepositoryImpl(
      remoteDatasource: _TimeoutRoutineDatasource(),
    );

    test('maps TimeoutException to friendly NetworkFailure without technical text', () async {
      await expectLater(
        repository.getUserRoutines(1),
        throwsA(
          isA<NetworkFailure>().having(
            (f) => f.message,
            'message',
            NetworkFailure.serverWakingTimeoutMessage,
          ),
        ),
      );
    });
  });
}
