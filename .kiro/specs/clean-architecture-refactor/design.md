# Design Document: Clean Architecture Refactor

## Overview

This design document outlines the refactoring of the Progressive Flutter gym tracking application from its current structure to a feature-first Clean Architecture pattern. The refactoring will reorganize existing code into three distinct layers per feature (data, domain, presentation) while maintaining all existing functionality.

### Current State Analysis

The Progressive app currently follows a basic feature-based organization with some architectural patterns:

- **Features**: Auth, workouts, profile, and home modules exist under `lib/features/`
- **Core Services**: Shared utilities like `ApiClient`, `SecureStorageService`, and constants
- **Mixed Responsibilities**: Current classes like `AuthService` and `WorkoutService` combine data access, business logic, and error handling
- **Direct API Integration**: Services directly make HTTP calls and handle JSON parsing
- **DTO/Entity Confusion**: Classes like `UserDTO` and `Exercise` serve dual purposes as both data transfer objects and business entities

### Target Architecture

The refactored architecture will implement Clean Architecture principles:

- **Domain Layer**: Pure Dart business logic with entities, repository interfaces, and use cases
- **Data Layer**: External communication handling with datasources, DTOs, and repository implementations  
- **Presentation Layer**: UI components that delegate business actions to use cases
- **Dependency Inversion**: All layers depend on domain abstractions, not concrete implementations
- **Feature Independence**: Each feature module is self-contained with clear boundaries

### Benefits

- **Testability**: Pure domain logic can be unit tested without Flutter dependencies
- **Maintainability**: Clear separation of concerns makes code easier to understand and modify
- **Flexibility**: Repository pattern allows swapping data sources without affecting business logic
- **Scalability**: New features can be added following established patterns
- **API Independence**: Changes to backend API only affect data layer DTOs and mapping logic

## Architecture

### Layer Dependencies

The architecture follows the dependency rule where dependencies point inward:

```
Presentation Layer → Domain Layer ← Data Layer
```

- **Domain Layer**: Contains business entities, repository interfaces, and use cases (pure Dart)
- **Data Layer**: Implements repository interfaces, handles API communication and data persistence
- **Presentation Layer**: Contains UI components, screens, and state management
- **Core Module**: Shared utilities and services used across all features

### Feature Module Structure

Each feature follows this standardized structure:

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   └── {feature}_remote_datasource.dart
│   ├── models/
│   │   └── {entity}_dto.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {entity}.dart
│   ├── repositories/
│   │   └── {feature}_repository.dart
│   └── use_cases/
│       ├── {action}_use_case.dart
│       └── ...
└── presentation/
    ├── screens/
    │   └── {feature}_screen.dart
    └── widgets/
        └── {feature}_widgets.dart
```

### Core Module Organization

The core module provides shared functionality:

```
lib/core/
├── network/
│   ├── api_client.dart
│   └── api_constants.dart
├── storage/
│   └── secure_storage_service.dart
├── theme/
│   └── app_theme.dart
├── utils/
│   └── validators.dart
└── widgets/
    └── shared_widgets.dart
```

## Components and Interfaces

### Domain Layer Components

#### Entities
Pure Dart classes representing business concepts:

```dart
// lib/features/auth/domain/entities/user.dart
class User {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.isPremium,
    this.languagePreference,
    this.createdAt,
  });
}
```

#### Repository Interfaces
Abstract contracts defining data operations:

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<String> login(String username, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
}
```

#### Use Cases
Single-responsibility business actions:

```dart
// lib/features/auth/domain/use_cases/login_user.dart
class LoginUser {
  final AuthRepository repository;
  
  LoginUser(this.repository);
  
  Future<User> call(String username, String password) async {
    final token = await repository.login(username, password);
    return await repository.getCurrentUser();
  }
}
```

### Data Layer Components

#### DTOs (Data Transfer Objects)
Handle JSON serialization/deserialization:

```dart
// lib/features/auth/data/models/user_dto.dart
class UserDto {
  final int id;
  final String username;
  final String email;
  final bool premium;
  final String? languagePreference;
  final String? createdAt;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.premium,
    this.languagePreference,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      premium: json['premium'] ?? false,
      languagePreference: json['languagePreference'],
      createdAt: json['createdAt'],
    );
  }

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      isPremium: premium,
      languagePreference: languagePreference,
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
    );
  }
}
```

#### Datasources
Handle raw API communication:

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
abstract class AuthRemoteDatasource {
  Future<String> login(String username, String password);
  Future<UserDto> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final ApiClient apiClient;
  
  AuthRemoteDatasourceImpl(this.apiClient);
  
  @override
  Future<String> login(String username, String password) async {
    final response = await apiClient.post(
      Uri.parse(ApiConstants.loginEndpoint),
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Login failed');
    }
  }
}
```

#### Repository Implementations
Bridge between domain and data:

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final SecureStorageService storageService;
  
  AuthRepositoryImpl(this.remoteDatasource, this.storageService);
  
  @override
  Future<String> login(String username, String password) async {
    final token = await remoteDatasource.login(username, password);
    await storageService.saveToken(token);
    return token;
  }
  
  @override
  Future<User?> getCurrentUser() async {
    final token = await storageService.readToken();
    if (token == null) return null;
    
    final userDto = await remoteDatasource.getCurrentUser();
    return userDto.toEntity();
  }
}
```

### Presentation Layer Components

#### Screens
UI components that use domain use cases:

```dart
// lib/features/auth/presentation/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  final LoginUser loginUseCase;
  
  const LoginScreen({required this.loginUseCase, Key? key}) : super(key: key);
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleLogin() async {
    try {
      final user = await widget.loginUseCase(username, password);
      // Navigate to home screen
    } catch (e) {
      // Show error message
    }
  }
}
```

## Data Models

### Authentication Domain

#### User Entity
```dart
class User {
  final int id;
  final String username;
  final String email;
  final bool isPremium;
  final String? languagePreference;
  final DateTime? createdAt;
}
```

#### UserDto
```dart
class UserDto {
  final int id;
  final String username;
  final String email;
  final bool premium;
  final String? languagePreference;
  final String? createdAt;
  
  User toEntity() { /* conversion logic */ }
  factory UserDto.fromJson(Map<String, dynamic> json) { /* parsing logic */ }
}
```

### Workouts Domain

#### Exercise Entity
```dart
class Exercise {
  final int id;
  final String name;
  final String description;
  final String primaryMuscle;
  final String equipment;
  final List<String> secondaryMuscles;
}
```

#### Routine Entity
```dart
class Routine {
  final int id;
  final String name;
  final List<Exercise> exercises;
  final DateTime createdAt;
}
```

#### Workout Entity
```dart
class Workout {
  final int id;
  final int routineId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutSet> sets;
}
```

#### WorkoutSet Entity
```dart
class WorkoutSet {
  final int exerciseId;
  final int reps;
  final double weight;
  final DateTime timestamp;
}
```

### Profile Domain

#### UserProfile Entity
```dart
class UserProfile {
  final int userId;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? preferredLanguage;
  final Map<String, dynamic> preferences;
}
```

### Data Transfer Objects

Each entity has a corresponding DTO in the data layer that handles JSON serialization and provides conversion methods to domain entities. DTOs contain the exact field names and types expected by the Spring Boot API, while entities represent the business concepts in a clean, framework-independent way.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Domain Layer Purity

*For any* file in the domain layer, the file should not import any Flutter framework packages or widgets.

**Validates: Requirements 2.1, 2.7**

### Property 2: Use Case Dependency Abstraction

*For any* use case class, the use case should depend only on repository interface abstractions, not concrete implementations.

**Validates: Requirements 2.6, 14.6**

### Property 3: DTO to Entity Conversion

*For any* DTO class in the data layer, the DTO should provide a method to convert to its corresponding domain entity.

**Validates: Requirements 3.5**

### Property 4: Repository Data Transformation

*For any* repository implementation method that receives data from a datasource, the method should return domain entities, not DTOs.

**Validates: Requirements 3.6, 12.5**

### Property 5: Data Layer Error Handling

*For any* datasource method that makes API calls, the method should properly handle JSON parsing errors and API error responses.

**Validates: Requirements 3.7**

### Property 6: Presentation Layer Use Case Dependency

*For any* screen or widget in the presentation layer that requires business logic, the component should invoke use case classes from the domain layer, not repositories or datasources directly.

**Validates: Requirements 4.3**

### Property 7: Presentation Layer Business Logic Separation

*For any* file in the presentation layer, the file should not contain business logic or data transformation code.

**Validates: Requirements 4.4**

### Property 8: Presentation Layer Entity Usage

*For any* presentation layer component that displays data, the component should work with entity models from the domain layer, not DTOs.

**Validates: Requirements 4.5, 12.6**

### Property 9: Presentation Layer Event Delegation

*For any* user input event in the presentation layer, the event handler should delegate actions to use cases.

**Validates: Requirements 4.6**

### Property 10: Authentication Token Storage

*For any* successful login operation, the authentication use case should store the JWT token via the repository.

**Validates: Requirements 5.6**

### Property 11: Authentication Behavior Preservation

*For any* authentication operation (login, logout, token validation), the behavior should be identical to the pre-refactored version.

**Validates: Requirements 5.7**

### Property 12: Workout Behavior Preservation

*For any* workout operation (creating routines, starting workouts, logging exercises, viewing history), the behavior should be identical to the pre-refactored version.

**Validates: Requirements 6.8**

### Property 13: Profile Behavior Preservation

*For any* profile operation (fetching profile, updating profile), the behavior should be identical to the pre-refactored version.

**Validates: Requirements 7.6**

### Property 14: Core Module Feature Independence

*For any* file in the core module, the file should not contain feature-specific business logic.

**Validates: Requirements 8.6**

### Property 15: Feature Core Import Pattern

*For any* feature module that requires shared functionality, the feature should import from lib/core/, not from other features.

**Validates: Requirements 8.7**

### Property 16: Domain Layer Dependency Isolation

*For any* file in the domain layer, the file should not import from data layer or presentation layer.

**Validates: Requirements 9.1**

### Property 17: Data Layer Domain Dependency

*For any* file in the data layer, the file should only import from the domain layer and core module.

**Validates: Requirements 9.2**

### Property 18: Presentation Layer Domain Dependency

*For any* file in the presentation layer, the file should only import from the domain layer and core module.

**Validates: Requirements 9.3**

### Property 19: Dependency Flow Compliance

*For any* feature module, the dependency flow should follow the pattern: Presentation → Domain ← Data.

**Validates: Requirements 9.6**

### Property 20: Login Flow Preservation

*For any* user with valid credentials, logging in should authenticate the user and navigate to the home screen.

**Validates: Requirements 10.1**

### Property 21: Routine Creation Preservation

*For any* routine creation operation, the routine should be saved and displayed in the routines list.

**Validates: Requirements 10.2**

### Property 22: Workout Tracking Preservation

*For any* workout session, starting a workout should enable tracking of exercises and sets.

**Validates: Requirements 10.3**

### Property 23: Profile Display Preservation

*For any* user profile request, the profile view should display user information correctly.

**Validates: Requirements 10.4**

### Property 24: Plate Calculator Preservation

*For any* weight input to the plate calculator, the calculator should compute correct plate combinations.

**Validates: Requirements 10.5**

### Property 25: Logout Flow Preservation

*For any* logout operation, the system should clear the JWT token and return to the login screen.

**Validates: Requirements 10.6**

### Property 26: Overall Behavior Preservation

*For any* existing feature functionality, the behavior should remain unchanged after refactoring.

**Validates: Requirements 10.7**

### Property 27: File Naming Convention

*For any* file in the project, the filename should follow snake_case naming convention.

**Validates: Requirements 11.1**

### Property 28: Class Naming Convention

*For any* class in the project, the class name should follow PascalCase naming convention.

**Validates: Requirements 11.2**

### Property 29: Variable and Function Naming Convention

*For any* variable or function in the project, the name should follow camelCase naming convention.

**Validates: Requirements 11.3**

### Property 30: Private Member Naming Convention

*For any* private member in the project, the name should be prefixed with an underscore.

**Validates: Requirements 11.4**

### Property 31: Intra-Feature Import Convention

*For any* import within the same feature module, the import should use relative paths.

**Validates: Requirements 11.5**

### Property 32: Cross-Feature Import Convention

*For any* import from other features or core module, the import should use absolute paths from lib/.

**Validates: Requirements 11.6**

### Property 33: Terminology Consistency

*For any* code element (class, variable, function), the naming should be consistent with the terminology defined in the glossary.

**Validates: Requirements 11.7**

### Property 34: DTO Entity Separation

*For any* class in the project, the class should not serve both DTO and Entity purposes simultaneously.

**Validates: Requirements 12.3**

### Property 35: API Change Isolation

*For any* backend API response format change, the changes should only affect data layer DTOs and mapping logic, not domain or presentation layers.

**Validates: Requirements 12.4**

### Property 36: Use Case Coordination

*For any* use case execution, the use case should coordinate between repository interfaces to complete the business action.

**Validates: Requirements 13.5**

### Property 37: Use Case Return Types

*For any* use case method, the method should return domain entities or error results, not DTOs.

**Validates: Requirements 13.6**

### Property 38: Use Case Logic Purity

*For any* use case class, the class should contain only business logic without UI or data access implementation details.

**Validates: Requirements 13.7**

### Property 39: Repository Datasource Delegation

*For any* repository implementation that accesses data, the implementation should delegate to datasource classes.

**Validates: Requirements 14.4**

### Property 40: Repository Error Transformation

*For any* repository implementation error case, the implementation should transform exceptions into domain-appropriate errors.

**Validates: Requirements 14.5**

### Property 41: ApiClient Usage

*For any* HTTP request in the data layer, the request should use ApiClient from lib/core/network/.

**Validates: Requirements 15.1**

### Property 42: ApiConstants Usage

*For any* API endpoint reference in the data layer, the reference should use constants from ApiConstants.

**Validates: Requirements 15.2**

### Property 43: Authentication Header Inclusion

*For any* authenticated API request, the datasource should include the JWT token in Authorization headers.

**Validates: Requirements 15.3**

### Property 44: API Error Handling

*For any* backend API error response, the datasource should parse error responses and propagate them appropriately.

**Validates: Requirements 15.4**

### Property 45: JSON Format Compatibility

*For any* API request or response, the data layer should maintain JSON format compatibility with the backend API.

**Validates: Requirements 15.5**

### Property 46: HTTP Request Compatibility

*For any* API endpoint currently in use, the refactored code should make identical HTTP requests to the original implementation.

**Validates: Requirements 15.6**

## Error Handling

### Domain Layer Error Handling

The domain layer defines custom exception types that represent business rule violations:

```dart
// lib/core/errors/failures.dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
```

### Data Layer Error Handling

Repository implementations catch and transform exceptions from datasources:

```dart
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User> login(String username, String password) async {
    try {
      final token = await remoteDatasource.login(username, password);
      await storageService.saveToken(token);
      return await getCurrentUser();
    } on SocketException {
      throw const NetworkFailure('No internet connection');
    } on HttpException catch (e) {
      if (e.message.contains('401')) {
        throw const AuthenticationFailure('Invalid credentials');
      }
      throw NetworkFailure('Server error: ${e.message}');
    } catch (e) {
      throw NetworkFailure('Unexpected error: $e');
    }
  }
}
```

### Presentation Layer Error Handling

UI components handle domain failures and display appropriate messages:

```dart
class LoginScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await loginUseCase(username, password);
          Navigator.pushReplacement(context, HomeScreen.route());
        } on AuthenticationFailure catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        } on NetworkFailure catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      },
      child: Text('Login'),
    );
  }
}
```

### Error Propagation Strategy

1. **Datasources**: Catch HTTP and JSON parsing exceptions, throw domain-specific exceptions
2. **Repositories**: Transform datasource exceptions into domain failures
3. **Use Cases**: Let domain failures propagate to presentation layer
4. **Presentation**: Catch domain failures and display user-friendly messages

## Testing Strategy

### Dual Testing Approach

The refactored architecture will use both unit testing and property-based testing to ensure comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs
- Both approaches are complementary and necessary for comprehensive coverage

### Unit Testing Strategy

Unit tests will focus on:

- **Specific Examples**: Concrete test cases that demonstrate correct behavior
- **Integration Points**: Interactions between layers and components  
- **Edge Cases**: Boundary conditions and error scenarios
- **Mocking**: Isolate units under test using repository interfaces and use case abstractions

Example unit test structure:

```dart
// test/features/auth/domain/use_cases/login_user_test.dart
void main() {
  group('LoginUser', () {
    late MockAuthRepository mockRepository;
    late LoginUser useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUser(mockRepository);
    });

    test('should return user when login succeeds', () async {
      // Arrange
      const user = User(id: 1, username: 'test', email: 'test@example.com', isPremium: false);
      when(() => mockRepository.login('test', 'password')).thenAnswer((_) async => 'token');
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async => user);

      // Act
      final result = await useCase('test', 'password');

      // Assert
      expect(result, equals(user));
      verify(() => mockRepository.login('test', 'password')).called(1);
    });
  });
}
```

### Property-Based Testing Strategy

Property-based testing will use the `test` package with custom generators to verify universal properties. Each property test will:

- Run a minimum of 100 iterations per test
- Reference the corresponding design document property
- Use the tag format: **Feature: clean-architecture-refactor, Property {number}: {property_text}**

Example property test:

```dart
// test/features/auth/data/models/user_dto_test.dart
void main() {
  group('UserDto Properties', () {
    test('DTO to Entity conversion preserves data integrity', () {
      // Feature: clean-architecture-refactor, Property 3: DTO to Entity Conversion
      for (int i = 0; i < 100; i++) {
        // Generate random UserDto
        final dto = generateRandomUserDto();
        
        // Convert to entity
        final entity = dto.toEntity();
        
        // Verify data integrity
        expect(entity.id, equals(dto.id));
        expect(entity.username, equals(dto.username));
        expect(entity.email, equals(dto.email));
        expect(entity.isPremium, equals(dto.premium));
      }
    });
  });
}
```

### Testing Layer Organization

Tests will mirror the lib/ directory structure:

```
test/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── use_cases/
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   └── [other features...]
└── core/
    ├── network/
    ├── storage/
    └── widgets/
```

### Mock Strategy

- **Repository Interfaces**: Mock in use case tests to isolate business logic
- **Datasources**: Mock in repository tests to isolate data transformation
- **Use Cases**: Mock in presentation tests to isolate UI behavior
- **ApiClient**: Mock in datasource tests to isolate HTTP communication

### Integration Testing

Integration tests will verify:

- **End-to-End Flows**: Complete user journeys (login → home → workout)
- **Layer Integration**: Proper communication between data, domain, and presentation layers
- **API Integration**: Real HTTP communication with backend services (using test environment)
- **Storage Integration**: Token persistence and retrieval flows

### Test Configuration

Property-based tests will be configured with:

```dart
// test/test_config.dart
const int propertyTestIterations = 100;
const String featureName = 'clean-architecture-refactor';

String propertyTestTag(int propertyNumber, String propertyText) {
  return 'Feature: $featureName, Property $propertyNumber: $propertyText';
}
```

### Behavioral Preservation Testing

Special focus on testing that refactored functionality behaves identically to the original:

- **Authentication Flow**: Login, logout, token management
- **Workout Operations**: Routine creation, exercise logging, history viewing
- **Profile Management**: Profile fetching and updating
- **UI Interactions**: Navigation, form validation, error display

These tests will use both unit and property-based approaches to ensure comprehensive coverage of the refactoring requirements.