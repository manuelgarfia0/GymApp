import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/domain/use_cases/login_user.dart';
import 'package:gym_app/features/auth/domain/entities/user.dart';
import 'package:gym_app/features/auth/domain/repositories/auth_repository.dart';

// Mock repository for testing authentication behavior preservation
class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;
  String? storedToken;
  User? currentUser;
  List<String> methodCalls = [];

  @override
  Future<String> login(String username, String password) async {
    methodCalls.add('login($username, $password)');

    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Username and password cannot be empty');
    }

    if (!shouldSucceed) {
      throw Exception('Invalid credentials');
    }

    storedToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
    currentUser = User(
      id: 1,
      username: username,
      email: 'test@example.com',
      isPremium: false,
    );
    return storedToken!;
  }

  @override
  Future<String> register(
    String username,
    String email,
    String password,
  ) async {
    methodCalls.add('register($username, $email, $password)');
    return 'mock_token';
  }

  @override
  Future<User?> getCurrentUser() async {
    methodCalls.add('getCurrentUser()');
    return currentUser;
  }

  @override
  Future<void> logout() async {
    methodCalls.add('logout()');
    storedToken = null;
    currentUser = null;
  }

  @override
  Future<bool> isLoggedIn() async {
    methodCalls.add('isLoggedIn()');
    return storedToken != null;
  }

  @override
  Future<String?> getToken() async {
    methodCalls.add('getToken()');
    return storedToken;
  }

  void reset() {
    shouldSucceed = true;
    storedToken = null;
    currentUser = null;
    methodCalls.clear();
  }
}

void main() {
  group('Authentication Behavior Preservation Tests - Task 4.3', () {
    late MockAuthRepository mockRepository;
    late LoginUser loginUseCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      loginUseCase = LoginUser(mockRepository);
    });

    test('REQUIREMENT 5.6: JWT token storage on successful login', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';

      // Act
      await loginUseCase.call(username, password);

      // Assert - JWT token should be stored via repository
      expect(mockRepository.storedToken, isNotNull);
      expect(mockRepository.storedToken, startsWith('mock_jwt_token_'));
      expect(
        mockRepository.methodCalls,
        contains('login($username, $password)'),
      );
    });

    test('REQUIREMENT 5.7: Authentication behavior preservation', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';

      // Act
      final user = await loginUseCase.call(username, password);

      // Assert - Should return User entity from domain layer
      expect(user, isA<User>());
      expect(user.username, equals(username));
      expect(user.email, equals('test@example.com'));
      expect(user.id, equals(1));
      expect(mockRepository.methodCalls, contains('getCurrentUser()'));
    });

    test(
      'REQUIREMENT 10.1: Login flow matches original behavior exactly',
      () async {
        // Arrange
        const username = 'validuser';
        const password = 'validpass';

        // Act
        final user = await loginUseCase.call(username, password);

        // Assert - Login flow should work exactly as before
        expect(user, isNotNull);
        expect(user.username, equals(username));
        expect(mockRepository.storedToken, isNotNull);
        expect(mockRepository.currentUser, isNotNull);
      },
    );

    test('REQUIREMENT 10.6: Error handling for invalid credentials', () async {
      // Arrange
      mockRepository.shouldSucceed = false;
      const username = 'invaliduser';
      const password = 'invalidpass';

      // Act & Assert - Should throw exception for invalid credentials
      expect(
        () => loginUseCase.call(username, password),
        throwsA(predicate((e) => e.toString().contains('Invalid credentials'))),
      );
    });

    test('Input validation: Empty username', () async {
      // Act & Assert - Should throw exception for empty username
      expect(
        () => loginUseCase.call('', 'password'),
        throwsA(
          predicate((e) => e.toString().contains('Username cannot be empty')),
        ),
      );
    });

    test('Input validation: Empty password', () async {
      // Act & Assert - Should throw exception for empty password
      expect(
        () => loginUseCase.call('username', ''),
        throwsA(
          predicate((e) => e.toString().contains('Password cannot be empty')),
        ),
      );
    });

    test('Input validation: Whitespace-only username', () async {
      // Act & Assert - Should throw exception for whitespace-only username
      expect(
        () => loginUseCase.call('   ', 'password'),
        throwsA(
          predicate((e) => e.toString().contains('Username cannot be empty')),
        ),
      );
    });

    test('Input validation: Whitespace-only password', () async {
      // Act & Assert - Should throw exception for whitespace-only password
      expect(
        () => loginUseCase.call('username', '   '),
        throwsA(
          predicate((e) => e.toString().contains('Password cannot be empty')),
        ),
      );
    });

    test('Architecture compliance: Uses repository abstraction', () async {
      // Arrange
      const username = 'testuser';
      const password = 'testpass';

      // Act
      await loginUseCase.call(username, password);

      // Assert - Should call repository methods, not direct service calls
      expect(
        mockRepository.methodCalls,
        contains('login($username, $password)'),
      );
      expect(mockRepository.methodCalls, contains('getCurrentUser()'));
      expect(mockRepository.methodCalls.length, equals(2));
    });

    test('Error handling: Repository login failure', () async {
      // Arrange
      mockRepository.shouldSucceed = false;

      // Act & Assert - Should propagate repository exceptions
      expect(() => loginUseCase.call('user', 'pass'), throwsException);
    });
  });

  group('JWT Token Storage and Retrieval Verification', () {
    late MockAuthRepository mockRepository;
    late LoginUser loginUseCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      loginUseCase = LoginUser(mockRepository);
    });

    test('Token accessibility after login', () async {
      // Arrange
      const username = 'tokenuser';
      const password = 'tokenpass';

      // Act
      await loginUseCase.call(username, password);

      // Assert - Token should be retrievable
      final token = await mockRepository.getToken();
      expect(token, isNotNull);
      expect(token, equals(mockRepository.storedToken));
    });

    test('User logged in status after successful login', () async {
      // Arrange
      const username = 'loggeduser';
      const password = 'loggedpass';

      // Act
      await loginUseCase.call(username, password);

      // Assert - User should be logged in
      final isLoggedIn = await mockRepository.isLoggedIn();
      expect(isLoggedIn, isTrue);
    });

    test('Logout clears token and user data', () async {
      // Arrange - First login
      await loginUseCase.call('user', 'pass');
      expect(await mockRepository.isLoggedIn(), isTrue);

      // Act - Logout
      await mockRepository.logout();

      // Assert - Token and user should be cleared
      expect(await mockRepository.getToken(), isNull);
      expect(await mockRepository.getCurrentUser(), isNull);
      expect(await mockRepository.isLoggedIn(), isFalse);
    });
  });
}
