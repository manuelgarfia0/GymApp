import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:gym_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:gym_app/features/auth/data/models/user_dto.dart';
import 'package:gym_app/features/auth/domain/entities/user.dart';
import 'package:gym_app/core/storage/secure_storage_service.dart';
import 'package:gym_app/core/errors/failures.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDatasource mockRemoteDatasource;
  late MockSecureStorageService mockStorageService;

  setUp(() {
    mockRemoteDatasource = MockAuthRemoteDatasource();
    mockStorageService = MockSecureStorageService();
    repository = AuthRepositoryImpl(
      remoteDatasource: mockRemoteDatasource,
      storageService: mockStorageService,
    );
  });

  group('login', () {
    const tUsername = 'testuser';
    const tPassword = 'password123';
    const tToken = 'jwt_token_123';

    test('should return token and store it when login succeeds', () async {
      // Arrange
      when(
        () => mockRemoteDatasource.login(tUsername, tPassword),
      ).thenAnswer((_) async => tToken);
      when(() => mockStorageService.saveToken(tToken)).thenAnswer((_) async {});

      // Act
      final result = await repository.login(tUsername, tPassword);

      // Assert
      expect(result, equals(tToken));
      verify(() => mockRemoteDatasource.login(tUsername, tPassword)).called(1);
      verify(() => mockStorageService.saveToken(tToken)).called(1);
    });

    test('should throw NetworkFailure when login fails', () async {
      // Arrange
      when(
        () => mockRemoteDatasource.login(tUsername, tPassword),
      ).thenThrow(Exception('Invalid credentials'));

      // Act & Assert
      expect(
        () => repository.login(tUsername, tPassword),
        throwsA(isA<NetworkFailure>()),
      );
      verifyNever(() => mockStorageService.saveToken(any()));
    });
  });

  group('getCurrentUser', () {
    const tToken = 'jwt_token_123';
    const tUserDto = UserDto(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      isPremium: true,
      languagePreference: 'en',
      createdAt: '2024-01-01T00:00:00Z',
      publicProfile: true,
    );

    test(
      'should return User entity when token exists and API call succeeds',
      () async {
        // Arrange
        when(
          () => mockStorageService.readToken(),
        ).thenAnswer((_) async => tToken);
        when(
          () => mockRemoteDatasource.getCurrentUser(),
        ).thenAnswer((_) async => tUserDto);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isA<User>());
        expect(result!.id, equals(tUserDto.id));
        expect(result.username, equals(tUserDto.username));
        expect(result.email, equals(tUserDto.email));
        expect(result.isPremium, equals(tUserDto.isPremium));
        verify(() => mockStorageService.readToken()).called(1);
        verify(() => mockRemoteDatasource.getCurrentUser()).called(1);
      },
    );

    test('should return null when no token exists', () async {
      // Arrange
      when(() => mockStorageService.readToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, isNull);
      verify(() => mockStorageService.readToken()).called(1);
      verifyNever(() => mockRemoteDatasource.getCurrentUser());
    });

    test(
      'should throw AuthenticationFailure and clear token when API call fails',
      () async {
        // Arrange
        when(
          () => mockStorageService.readToken(),
        ).thenAnswer((_) async => tToken);
        when(
          () => mockRemoteDatasource.getCurrentUser(),
        ).thenThrow(Exception('Unauthorized'));
        when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          () => repository.getCurrentUser(),
          throwsA(isA<AuthenticationFailure>()),
        );
        verify(() => mockStorageService.readToken()).called(1);
        verify(() => mockRemoteDatasource.getCurrentUser()).called(1);
        verify(() => mockStorageService.deleteToken()).called(1);
      },
    );
  });

  group('logout', () {
    test('should clear stored token', () async {
      // Arrange
      when(() => mockStorageService.deleteToken()).thenAnswer((_) async {});

      // Act
      await repository.logout();

      // Assert
      verify(() => mockStorageService.deleteToken()).called(1);
    });

    test('should complete even if storage fails', () async {
      // Arrange
      when(
        () => mockStorageService.deleteToken(),
      ).thenThrow(Exception('Storage error'));

      // Act & Assert - should not throw
      await repository.logout();
      verify(() => mockStorageService.deleteToken()).called(1);
    });
  });

  group('isLoggedIn', () {
    const tToken = 'jwt_token_123';
    const tUserDto = UserDto(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      isPremium: false,
      publicProfile: true,
    );

    test(
      'should return true when token exists and user can be retrieved',
      () async {
        // Arrange
        when(
          () => mockStorageService.readToken(),
        ).thenAnswer((_) async => tToken);
        when(
          () => mockRemoteDatasource.getCurrentUser(),
        ).thenAnswer((_) async => tUserDto);

        // Act
        final result = await repository.isLoggedIn();

        // Assert
        expect(result, isTrue);
      },
    );

    test('should return false when no token exists', () async {
      // Arrange
      when(() => mockStorageService.readToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, isFalse);
    });

    test('should return false when token is empty', () async {
      // Arrange
      when(() => mockStorageService.readToken()).thenAnswer((_) async => '');

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, isFalse);
    });
  });
}
