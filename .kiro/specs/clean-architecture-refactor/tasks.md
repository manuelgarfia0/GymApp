# Implementation Plan: Clean Architecture Refactor

## Overview

This implementation plan refactors the Progressive Flutter gym tracking application from its current structure to a feature-first Clean Architecture pattern. The refactoring will reorganize existing code into three distinct layers per feature (data, domain, presentation) while maintaining all existing functionality. Each task builds incrementally to ensure the app remains functional throughout the refactoring process.

## Tasks

- [x] 1. Set up core module structure and shared utilities
  - Create standardized directory structure under `lib/core/`
  - Organize existing shared services into proper subdirectories
  - Ensure ApiClient, SecureStorageService, and constants are properly organized
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 2. Create domain layer foundation for authentication feature
  - [x] 2.1 Create authentication domain entities and repository interface
    - Define User entity with pure Dart (no Flutter dependencies)
    - Create AuthRepository interface with method signatures
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 5.2_
  
  - [ ]* 2.2 Write property test for User entity
    - **Property 1: Domain Layer Purity**
    - **Validates: Requirements 2.1, 2.7**
  
  - [x] 2.3 Create authentication use cases
    - Implement LoginUser, RegisterUser, LogoutUser, GetCurrentUser use cases
    - Ensure use cases depend only on repository abstractions
    - _Requirements: 2.5, 2.6, 13.1, 13.2, 13.5_
  
  - [ ]* 2.4 Write property tests for authentication use cases
    - **Property 2: Use Case Dependency Abstraction**
    - **Validates: Requirements 2.6, 14.6**

- [x] 3. Implement authentication data layer
  - [x] 3.1 Create authentication DTOs and datasource
    - Define UserDto with JSON serialization methods
    - Implement AuthRemoteDatasource for API communication
    - _Requirements: 3.1, 3.2, 3.4, 5.3, 12.1, 12.2_
  
  - [ ]* 3.2 Write property test for DTO to entity conversion
    - **Property 3: DTO to Entity Conversion**
    - **Validates: Requirements 3.5**
  
  - [x] 3.3 Implement authentication repository
    - Create AuthRepositoryImpl that bridges datasource and domain
    - Handle JWT token storage via SecureStorageService
    - Transform DTOs to entities before returning to use cases
    - _Requirements: 3.3, 3.6, 5.4, 12.5, 14.1, 14.2_
  
  - [ ]* 3.4 Write property tests for repository data transformation
    - **Property 4: Repository Data Transformation**
    - **Validates: Requirements 3.6, 12.5**

- [x] 4. Refactor authentication presentation layer
  - [x] 4.1 Update login screen to use authentication use cases
    - Modify login_screen.dart to inject and use LoginUser use case
    - Remove direct service dependencies, delegate to use cases
    - Ensure UI works with domain entities, not DTOs
    - _Requirements: 4.3, 4.4, 4.5, 5.5, 12.6_
  
  - [ ]* 4.2 Write property tests for presentation layer dependencies
    - **Property 6: Presentation Layer Use Case Dependency**
    - **Validates: Requirements 4.3**
  
  - [x] 4.3 Verify authentication behavior preservation
    - Test login flow matches original behavior exactly
    - Verify JWT token storage and retrieval works correctly
    - _Requirements: 5.6, 5.7, 10.1, 10.6_
  
  - [ ]* 4.4 Write property tests for authentication behavior preservation
    - **Property 10: Authentication Token Storage**
    - **Property 11: Authentication Behavior Preservation**
    - **Validates: Requirements 5.6, 5.7**

- [x] 5. Checkpoint - Ensure authentication refactor is complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create domain layer foundation for workouts feature
  - [x] 6.1 Create workout domain entities
    - Define Exercise, Routine, Workout, WorkoutSet entities
    - Ensure pure Dart implementation without Flutter dependencies
    - _Requirements: 2.1, 2.3, 6.2_
  
  - [x] 6.2 Create workout repository interfaces
    - Define ExerciseRepository, RoutineRepository, WorkoutRepository interfaces
    - _Requirements: 2.4, 6.3, 14.1_
  
  - [x] 6.3 Create workout use cases
    - Implement CreateRoutine, GetRoutines, StartWorkout, LogExercise, GetWorkoutHistory use cases
    - _Requirements: 2.5, 6.4, 13.3_
  
  - [ ]* 6.4 Write property tests for workout domain layer
    - **Property 1: Domain Layer Purity**
    - **Property 2: Use Case Dependency Abstraction**
    - **Validates: Requirements 2.1, 2.6, 2.7**

- [x] 7. Implement workouts data layer
  - [x] 7.1 Create workout DTOs and datasources
    - Define ExerciseDto, RoutineDto, WorkoutDto, WorkoutSetDto with JSON serialization
    - Implement datasources for exercise, routine, and workout API endpoints
    - _Requirements: 3.1, 3.2, 3.4, 6.5, 6.6_
  
  - [ ]* 7.2 Write property tests for workout DTOs
    - **Property 3: DTO to Entity Conversion**
    - **Validates: Requirements 3.5**
  
  - [x] 7.3 Implement workout repository implementations
    - Create repository implementations that use datasources and transform DTOs to entities
    - _Requirements: 3.3, 3.6, 14.4_
  
  - [ ]* 7.4 Write property tests for workout repositories
    - **Property 4: Repository Data Transformation**
    - **Validates: Requirements 3.6, 12.5**

- [x] 8. Refactor workouts presentation layer
  - [x] 8.1 Update workout screens to use domain use cases
    - Refactor all workout screens to use workout use cases
    - Remove direct service dependencies
    - _Requirements: 4.3, 4.4, 6.7_
  
  - [x] 8.2 Verify workout behavior preservation
    - Test routine creation, workout tracking, exercise logging match original behavior
    - _Requirements: 6.8, 10.2, 10.3_
  
  - [ ]* 8.3 Write property tests for workout behavior preservation
    - **Property 12: Workout Behavior Preservation**
    - **Validates: Requirements 6.8**

- [x] 9. Create domain layer foundation for profile feature
  - [x] 9.1 Create profile domain entities and repository interface
    - Define UserProfile entity and ProfileRepository interface
    - _Requirements: 2.1, 2.3, 2.4, 7.2, 7.3_
  
  - [x] 9.2 Create profile use cases
    - Implement GetUserProfile, UpdateUserProfile use cases
    - _Requirements: 2.5, 7.3, 13.4_
  
  - [ ]* 9.3 Write property tests for profile domain layer
    - **Property 1: Domain Layer Purity**
    - **Property 2: Use Case Dependency Abstraction**
    - **Validates: Requirements 2.1, 2.6, 2.7**

- [x] 10. Implement profile data layer and presentation
  - [x] 10.1 Create profile DTOs, datasource, and repository implementation
    - Define UserProfileDto with JSON serialization
    - Implement ProfileRemoteDatasource and ProfileRepositoryImpl
    - _Requirements: 3.1, 3.2, 3.3, 7.4_
  
  - [x] 10.2 Refactor profile screen to use profile use cases
    - Update profile_screen.dart to use domain use cases
    - _Requirements: 4.3, 7.5_
  
  - [x] 10.3 Verify profile behavior preservation
    - Test profile fetching and updating match original behavior
    - _Requirements: 7.6, 10.4_
  
  - [ ]* 10.4 Write property tests for profile behavior preservation
    - **Property 13: Profile Behavior Preservation**
    - **Validates: Requirements 7.6**

- [x] 11. Checkpoint - Ensure core features are refactored
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement dependency injection and wiring
  - [x] 12.1 Set up dependency injection for all layers
    - Create factory methods or dependency injection setup
    - Wire datasources, repositories, and use cases together
    - Ensure presentation layer receives properly configured use cases
    - _Requirements: 9.1, 9.2, 9.3, 9.4_
  
  - [x] 12.2 Verify dependency flow compliance
    - Ensure all imports follow the correct dependency direction
    - Validate that domain layer has no Flutter dependencies
    - _Requirements: 9.1, 9.5, 9.6_
  
  - [ ]* 12.3 Write property tests for dependency compliance
    - **Property 16: Domain Layer Dependency Isolation**
    - **Property 17: Data Layer Domain Dependency**
    - **Property 18: Presentation Layer Domain Dependency**
    - **Property 19: Dependency Flow Compliance**
    - **Validates: Requirements 9.1, 9.2, 9.3, 9.6**

- [x] 13. Implement comprehensive error handling
  - [x] 13.1 Create domain failure classes
    - Define AuthenticationFailure, NetworkFailure, ValidationFailure classes
    - _Requirements: Error handling strategy from design_
  
  - [x] 13.2 Update repositories to handle and transform errors
    - Modify repository implementations to catch datasource exceptions and transform to domain failures
    - _Requirements: 14.5_
  
  - [x] 13.3 Update presentation layer error handling
    - Modify screens to catch domain failures and display user-friendly messages
    - _Requirements: Error handling strategy from design_
  
  - [ ]* 13.4 Write property tests for error handling
    - **Property 5: Data Layer Error Handling**
    - **Property 40: Repository Error Transformation**
    - **Validates: Requirements 3.7, 14.5**

- [x] 14. Verify API integration preservation
  - [x] 14.1 Ensure all API endpoints use ApiClient and ApiConstants
    - Verify datasources use ApiClient from lib/core/network/
    - Verify endpoint constants are used from ApiConstants
    - _Requirements: 15.1, 15.2_
  
  - [x] 14.2 Verify authentication headers and JSON compatibility
    - Ensure JWT tokens are included in authenticated requests
    - Verify JSON request/response format matches backend API
    - _Requirements: 15.3, 15.4, 15.5_
  
  - [ ]* 14.3 Write property tests for API integration
    - **Property 41: ApiClient Usage**
    - **Property 42: ApiConstants Usage**
    - **Property 43: Authentication Header Inclusion**
    - **Property 46: HTTP Request Compatibility**
    - **Validates: Requirements 15.1, 15.2, 15.3, 15.6**

- [x] 15. Implement naming and import conventions
  - [x] 15.1 Verify file and class naming conventions
    - Ensure all files use snake_case naming
    - Ensure all classes use PascalCase naming
    - Ensure variables and functions use camelCase
    - _Requirements: 11.1, 11.2, 11.3, 11.4_
  
  - [x] 15.2 Standardize import conventions
    - Use relative imports within same feature modules
    - Use absolute imports for cross-feature and core imports
    - _Requirements: 11.5, 11.6_
  
  - [ ]* 15.3 Write property tests for naming conventions
    - **Property 27: File Naming Convention**
    - **Property 28: Class Naming Convention**
    - **Property 29: Variable and Function Naming Convention**
    - **Property 30: Private Member Naming Convention**
    - **Validates: Requirements 11.1, 11.2, 11.3, 11.4**

- [x] 16. Comprehensive behavior preservation testing
  - [x] 16.1 Test complete user flows end-to-end
    - Verify login → home → workout creation → exercise logging flow
    - Test profile management and plate calculator functionality
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
  
  - [ ]* 16.2 Write property tests for complete behavior preservation
    - **Property 20: Login Flow Preservation**
    - **Property 21: Routine Creation Preservation**
    - **Property 22: Workout Tracking Preservation**
    - **Property 23: Profile Display Preservation**
    - **Property 24: Plate Calculator Preservation**
    - **Property 25: Logout Flow Preservation**
    - **Property 26: Overall Behavior Preservation**
    - **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7**

- [x] 17. Final integration testing and cleanup
  - [x] 17.1 Run comprehensive test suite
    - Execute all unit tests and property-based tests
    - Verify no regressions in functionality
    - _Requirements: All requirements validation_
  
  - [x] 17.2 Clean up unused code and imports
    - Remove old service classes that have been replaced
    - Clean up any unused imports or dead code
    - _Requirements: Code organization and maintainability_
  
  - [x] 17.3 Verify core module independence
    - Ensure core module contains no feature-specific logic
    - Verify features import from core appropriately
    - _Requirements: 8.6, 8.7_
  
  - [ ] 17.4 Write final property tests for architecture compliance
    - **Property 14: Core Module Feature Independence**
    - **Property 15: Feature Core Import Pattern**
    - **Property 34: DTO Entity Separation**
    - **Property 35: API Change Isolation**
    - **Validates: Requirements 8.6, 8.7, 12.3, 12.4**

- [x] 18. Final checkpoint - Ensure complete refactor success
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional property-based tests and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation throughout the refactor
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- The refactoring maintains all existing functionality while improving code organization
- Each feature is refactored independently to minimize risk and enable incremental progress