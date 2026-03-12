import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/profile/data/models/user_profile_dto.dart';
import 'package:gym_app/features/profile/domain/entities/user_profile.dart';

void main() {
  group('Profile Behavior Preservation Tests', () {
    test('DTO to Entity conversion preserves all data fields', () {
      // This test verifies that the refactored profile data layer
      // maintains the same data structure as the original UserDTO

      // Arrange - Create a DTO with all fields (simulating API response)
      final dto = UserProfileDto(
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        isPremium: true,
        languagePreference: 'en',
        createdAt: '2023-01-01T00:00:00Z',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: '1990-01-01T00:00:00Z',
        preferences: {'theme': 'dark', 'notifications': true},
      );

      // Act - Convert to entity (what the UI will receive)
      final entity = dto.toEntity();

      // Assert - Verify all original UserDTO fields are preserved
      expect(entity.userId, dto.id);
      expect(entity.username, dto.username);
      expect(entity.email, dto.email);
      expect(entity.isPremium, dto.isPremium);
      expect(entity.languagePreference, dto.languagePreference);
      expect(entity.firstName, dto.firstName);
      expect(entity.lastName, dto.lastName);
      expect(entity.preferences, dto.preferences);

      // Verify date parsing works correctly
      expect(entity.createdAt, isA<DateTime>());
      expect(entity.dateOfBirth, isA<DateTime>());
      expect(entity.createdAt!.year, 2023);
      expect(entity.dateOfBirth!.year, 1990);
    });

    test('Entity to DTO conversion maintains API compatibility', () {
      // This test verifies that updates can be sent back to the API
      // in the same format as the original implementation

      // Arrange - Create an entity (from UI updates)
      final entity = UserProfile(
        userId: 1,
        username: 'updateduser',
        email: 'updated@example.com',
        isPremium: false,
        languagePreference: 'es',
        firstName: 'Jane',
        lastName: 'Smith',
        dateOfBirth: DateTime(1985, 5, 15),
        preferences: {'theme': 'light'},
      );

      // Act - Convert to DTO (for API request)
      final dto = UserProfileDto.fromEntity(entity);

      // Assert - Verify API-compatible format
      expect(dto.id, entity.userId);
      expect(dto.username, entity.username);
      expect(dto.email, entity.email);
      expect(dto.isPremium, entity.isPremium);
      expect(dto.languagePreference, entity.languagePreference);
      expect(dto.firstName, entity.firstName);
      expect(dto.lastName, entity.lastName);
      expect(dto.preferences, entity.preferences);

      // Verify date serialization for API
      expect(dto.dateOfBirth, contains('1985-05-15'));
    });

    test(
      'JSON parsing maintains backward compatibility with original UserDTO',
      () {
        // This test verifies that the new DTO can parse the same JSON
        // that the original UserDTO could handle

        // Arrange - JSON response format from Spring Boot API (original format)
        final originalApiResponse = {
          'id': 42,
          'username': 'gymuser',
          'email': 'gym@example.com',
          'isPremium': true,
          'languagePreference': 'en',
          'createdAt': '2023-06-15T10:30:00Z',
        };

        // Act - Parse with new DTO
        final dto = UserProfileDto.fromJson(originalApiResponse);

        // Assert - Verify all original fields are correctly parsed
        expect(dto.id, 42);
        expect(dto.username, 'gymuser');
        expect(dto.email, 'gym@example.com');
        expect(dto.isPremium, true);
        expect(dto.languagePreference, 'en');
        expect(dto.createdAt, '2023-06-15T10:30:00Z');

        // Verify new fields handle null gracefully
        expect(dto.firstName, isNull);
        expect(dto.lastName, isNull);
        expect(dto.dateOfBirth, isNull);
        expect(dto.preferences, isNull);
      },
    );

    test('Profile display data matches original UserDTO behavior', () {
      // This test verifies that the UI will display the same information
      // as it did with the original UserDTO

      // Arrange - Simulate original UserDTO data
      final originalData = {
        'id': 1,
        'username': 'fitnessuser',
        'email': 'fitness@example.com',
        'isPremium': false,
        'languagePreference': null,
        'createdAt': '2023-01-01T00:00:00Z',
      };

      // Act - Process through new data layer
      final dto = UserProfileDto.fromJson(originalData);
      final entity = dto.toEntity();

      // Assert - Verify UI display values match original behavior
      expect(entity.username, 'fitnessuser'); // Username display
      expect(entity.email, 'fitness@example.com'); // Email display
      expect(entity.isPremium, false); // Premium status
      expect(entity.languagePreference, isNull); // Null handling

      // Verify premium display logic works the same
      final premiumText = entity.isPremium ? 'PRO Member' : 'Free Plan';
      expect(premiumText, 'Free Plan');
    });

    test('Error handling preserves original behavior', () {
      // This test verifies that error cases are handled the same way

      // Arrange - Invalid/empty JSON (edge case from original implementation)
      final invalidJson = <String, dynamic>{'isPremium': false};

      // Act - Parse with graceful defaults
      final dto = UserProfileDto.fromJson(invalidJson);

      // Assert - Verify same default behavior as original UserDTO
      expect(dto.id, isNull); // Null ID (no fallback in fromJson)
      expect(dto.username, isNull); // Null username (no fallback in fromJson)
      expect(dto.email, isNull); // Null email (no fallback in fromJson)
      expect(dto.isPremium, false); // Provided premium status
      expect(dto.languagePreference, isNull); // Null for optional fields
    });
  });
}
