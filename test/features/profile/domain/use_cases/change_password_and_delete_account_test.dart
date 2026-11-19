import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/errors/failures.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';
import 'package:gym_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_app/features/profile/domain/use_cases/change_password.dart';
import 'package:gym_app/features/profile/domain/use_cases/delete_account.dart';

class _FakeAccountRepo implements ProfileRepository {
  int? changedUserId;
  String? changedCurrent;
  String? changedNew;
  int? deletedUserId;
  String? deletedPassword;

  @override
  Future<void> changePassword(
    int userId,
    String currentPassword,
    String newPassword,
  ) async {
    changedUserId = userId;
    changedCurrent = currentPassword;
    changedNew = newPassword;
  }

  @override
  Future<void> deleteAccount(int userId, String password) async {
    deletedUserId = userId;
    deletedPassword = password;
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async => null;

  @override
  Future<UserProfile?> getUserProfile(int userId) async => null;

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async =>
      userProfile;
}

void main() {
  group('ChangePassword & DeleteAccount use cases', () {
    late _FakeAccountRepo repo;
    late ChangePassword changePassword;
    late DeleteAccount deleteAccount;

    setUp(() {
      repo = _FakeAccountRepo();
      changePassword = ChangePassword(repo);
      deleteAccount = DeleteAccount(repo);
    });

    test('ChangePassword validates inputs before calling repository', () async {
      await expectLater(
        changePassword(userId: 0, currentPassword: 'old', newPassword: 'newpass'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        changePassword(userId: 1, currentPassword: '', newPassword: 'newpass'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        changePassword(userId: 1, currentPassword: 'old', newPassword: '123'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        changePassword(userId: 1, currentPassword: 'same12', newPassword: 'same12'),
        throwsA(isA<ValidationFailure>()),
      );

      await changePassword(
        userId: 5,
        currentPassword: 'oldpass',
        newPassword: 'newpass123',
      );
      expect(repo.changedUserId, 5);
      expect(repo.changedCurrent, 'oldpass');
      expect(repo.changedNew, 'newpass123');
    });

    test('DeleteAccount validates userId and password', () async {
      await expectLater(
        deleteAccount(userId: 0, password: 'secret'),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        deleteAccount(userId: 4, password: ''),
        throwsA(isA<ValidationFailure>()),
      );

      await deleteAccount(userId: 4, password: 'secret');
      expect(repo.deletedUserId, 4);
      expect(repo.deletedPassword, 'secret');
    });
  });
}
