import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';
import 'package:gym_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_app/features/profile/domain/use_cases/get_current_user_profile.dart';

// Mock repository for testing
class MockProfileRepository implements ProfileRepository {
  UserProfile? _mockProfile;
  Exception? _mockException;

  void setMockProfile(UserProfile? profile) {
    _mockProfile = profile;
    _mockException = null;
  }

  void setMockException(Exception exception) {
    _mockException = exception;
    _mockProfile = null;
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockProfile;
  }

  @override
  Future<UserProfile?> getUserProfile(int userId) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return _mockProfile;
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile userProfile) async {
    if (_mockException != null) {
      throw _mockException!;
    }
    return userProfile;
  }
}

void main() {
  group('GetCurrentUserProfile', () {
    late MockProfileRepository mockRepository;
    late GetCurrentUserProfile useCase;

    setUp(() {
      mockRepository = MockProfileRepository();
      useCase = GetCurrentUserProfile(mockRepository);
    });

    test(
      'should return user profile when repository returns profile',
      () async {
        // Arrange
        const expectedProfile = UserProfile(
          userId: 1,
          username: 'testuser',
          email: 'test@example.com',
          isPremium: true,
          languagePreference: 'en',
        );
        mockRepository.setMockProfile(expectedProfile);

        // Act
        final result = await useCase();

        // Assert
        expect(result, equals(expectedProfile));
      },
    );

    test('should return null when repository returns null', () async {
      // Arrange
      mockRepository.setMockProfile(null);

      // Act
      final result = await useCase();

      // Assert
      expect(result, isNull);
    });

    test('should throw exception when repository throws exception', () async {
      // Arrange
      final exception = Exception('Network error');
      mockRepository.setMockException(exception);

      // Act & Assert
      expect(() => useCase(), throwsA(isA<Exception>()));
    });
  });
}
