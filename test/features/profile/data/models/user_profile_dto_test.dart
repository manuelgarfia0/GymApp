import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/profile/data/models/user_profile_dto.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';

void main() {
  group('UserProfileDto', () {
    test('should create UserProfileDto from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'isPremium': true,
        'languagePreference': 'en',
        'createdAt': '2023-01-01T00:00:00Z',
        'firstName': 'Test',
        'lastName': 'User',
        'dateOfBirth': '1990-01-01T00:00:00Z',
        'preferences': {'theme': 'dark'},
      };

      // Act
      final dto = UserProfileDto.fromJson(json);

      // Assert
      expect(dto.id, 1);
      expect(dto.username, 'testuser');
      expect(dto.email, 'test@example.com');
      expect(dto.isPremium, true);
      expect(dto.languagePreference, 'en');
      expect(dto.firstName, 'Test');
      expect(dto.lastName, 'User');
      expect(dto.preferences, {'theme': 'dark'});
    });

    test('should convert DTO to entity correctly', () {
      // Arrange
      final dto = UserProfileDto(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        isPremium: true,
        languagePreference: 'en',
        createdAt: '2023-01-01T00:00:00Z',
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '1990-01-01T00:00:00Z',
        preferences: {'theme': 'dark'},
      );

      // Act
      final entity = dto.toEntity();

      // Assert
      expect(entity.userId, 1);
      expect(entity.username, 'testuser');
      expect(entity.email, 'test@example.com');
      expect(entity.isPremium, true);
      expect(entity.languagePreference, 'en');
      expect(entity.firstName, 'Test');
      expect(entity.lastName, 'User');
      expect(entity.preferences, {'theme': 'dark'});
      expect(entity.createdAt, isA<DateTime>());
      expect(entity.dateOfBirth, isA<DateTime>());
    });

    test('should create DTO from entity correctly', () {
      // Arrange
      final entity = UserProfile(
        userId: 1,
        username: 'testuser',
        email: 'test@example.com',
        isPremium: true,
        languagePreference: 'en',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: DateTime.parse('1990-01-01T00:00:00Z'),
        preferences: {'theme': 'dark'},
      );

      // Act
      final dto = UserProfileDto.fromEntity(entity);

      // Assert
      expect(dto.id, 1);
      expect(dto.username, 'testuser');
      expect(dto.email, 'test@example.com');
      expect(dto.isPremium, true);
      expect(dto.languagePreference, 'en');
      expect(dto.firstName, 'Test');
      expect(dto.lastName, 'User');
      expect(dto.preferences, {'theme': 'dark'});
      expect(dto.createdAt, '2023-01-01T00:00:00.000Z');
      expect(dto.dateOfBirth, '1990-01-01T00:00:00.000Z');
    });

    test('should handle null values gracefully', () {
      // Arrange
      final json = {'isPremium': false};

      // Act
      final dto = UserProfileDto.fromJson(json);
      final entity = dto.toEntity();

      // Assert
      expect(dto.id, isNull);
      expect(dto.username, isNull);
      expect(dto.email, isNull);
      expect(dto.languagePreference, isNull);
      expect(dto.firstName, isNull);
      expect(dto.lastName, isNull);
      expect(dto.preferences, isNull);
      expect(entity.userId, 0); // Fallback in toEntity
      expect(entity.username, ''); // Fallback in toEntity
      expect(entity.email, ''); // Fallback in toEntity
      expect(entity.languagePreference, isNull);
      expect(entity.firstName, isNull);
      expect(entity.lastName, isNull);
      expect(entity.preferences, {});
    });

    test(
      'toJson should format dateOfBirth as YYYY-MM-DD and empty string when null',
      () {
        final dtoWithIso = UserProfileDto(
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          isPremium: false,
          dateOfBirth: '1990-01-01T00:00:00.000Z',
        );
        final dtoWithDateOnly = UserProfileDto(
          id: 2,
          username: 'testuser2',
          email: 'test2@example.com',
          isPremium: true,
          dateOfBirth: '1995-08-19',
        );
        final dtoWithNullDob = UserProfileDto(
          id: 3,
          username: 'testuser3',
          email: 'test3@example.com',
          isPremium: false,
          dateOfBirth: null,
        );

        expect(dtoWithIso.toJson()['dateOfBirth'], '1990-01-01');
        expect(dtoWithDateOnly.toJson()['dateOfBirth'], '1995-08-19');
        expect(dtoWithNullDob.toJson()['dateOfBirth'], '');
      },
    );

    test(
      'maps granular privacy flags with true defaults and preserves false roundtrip',
      () {
        final defaultsDto = UserProfileDto.fromJson({'isPremium': false});
        expect(defaultsDto.showDateOfBirth, isTrue);
        expect(defaultsDto.showGlobalStats, isTrue);
        expect(defaultsDto.showPublicRoutines, isTrue);

        final customDto = UserProfileDto.fromJson({
          'id': 8,
          'username': 'priv',
          'email': 'priv@test.com',
          'isPremium': false,
          'publicProfile': false,
          'showDateOfBirth': false,
          'showGlobalStats': false,
          'showPublicRoutines': true,
        });
        final entity = customDto.toEntity();
        expect(entity.publicProfile, isFalse);
        expect(entity.showDateOfBirth, isFalse);
        expect(entity.showGlobalStats, isFalse);
        expect(entity.showPublicRoutines, isTrue);

        final serialized = UserProfileDto.fromEntity(entity).toJson();
        expect(serialized['publicProfile'], isFalse);
        expect(serialized['showDateOfBirth'], isFalse);
        expect(serialized['showGlobalStats'], isFalse);
        expect(serialized['showPublicRoutines'], isTrue);
      },
    );
  });
}
