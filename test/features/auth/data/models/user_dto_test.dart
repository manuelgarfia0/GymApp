import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/models/user_dto.dart';
import 'package:gym_app/features/auth/domain/entities/user.dart';

void main() {
  group('UserDto', () {
    const tUserDto = UserDto(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      isPremium: true,
      languagePreference: 'en',
      createdAt: '2024-01-01T00:00:00Z',
      publicProfile: true,
    );

    const tUser = User(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      isPremium: true,
      languagePreference: 'en',
      createdAt: null, // Will be parsed from string
    );

    test('should create UserDto from JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'isPremium': true,
        'languagePreference': 'en',
        'createdAt': '2024-01-01T00:00:00Z',
        'publicProfile': true,
      };

      // Act
      final result = UserDto.fromJson(json);

      // Assert
      expect(result, equals(tUserDto));
    });

    test('should convert UserDto to JSON', () {
      // Arrange
      final expectedJson = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        'isPremium': true,
        'languagePreference': 'en',
        'createdAt': '2024-01-01T00:00:00Z',
        'publicProfile': true,
      };

      // Act
      final result = tUserDto.toJson();

      // Assert
      expect(result, equals(expectedJson));
    });

    test('should convert UserDto to User entity', () {
      // Act
      final result = tUserDto.toEntity();

      // Assert
      expect(result.id, equals(tUser.id));
      expect(result.username, equals(tUser.username));
      expect(result.email, equals(tUser.email));
      expect(result.isPremium, equals(tUser.isPremium));
      expect(result.languagePreference, equals(tUser.languagePreference));
      expect(result.createdAt, isA<DateTime>());
    });

    test('should handle null values in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'username': 'testuser',
        'email': 'test@example.com',
        // isPremium not provided - should default to false
        // languagePreference not provided - should be null
        // createdAt not provided - should be null
        // publicProfile not provided - should default to true
      };

      // Act
      final result = UserDto.fromJson(json);

      // Assert
      expect(result.id, equals(1));
      expect(result.username, equals('testuser'));
      expect(result.email, equals('test@example.com'));
      expect(result.isPremium, equals(false));
      expect(result.languagePreference, isNull);
      expect(result.createdAt, isNull);
      expect(result.publicProfile, equals(true));
    });

    test('should convert to entity with null createdAt', () {
      // Arrange
      const userDtoWithNullDate = UserDto(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        isPremium: false,
        languagePreference: null,
        createdAt: null,
        publicProfile: true,
      );

      // Act
      final result = userDtoWithNullDate.toEntity();

      // Assert
      expect(result.createdAt, isNull);
    });
  });
}
