# Bugfix Requirements Document

## Introduction

This document addresses multiple architectural and code quality issues in the Flutter gym app that are causing API failures, authentication inconsistencies, memory inefficiency, and maintenance burden. The issues span across data contract mismatches, storage inconsistencies, dependency injection problems, code duplication, redundant API calls, clean architecture violations, and production debug code.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app receives Exercise data from the Java Spring Boot API THEN the system fails to parse JSON because Flutter expects field names `primaryMuscle`, `equipment`, `secondaryMuscles` but Java sends `primaryMuscleName`, `equipmentName`, `secondaryMuscleNames`

1.2 WHEN HomeScreen attempts to read JWT token from SharedPreferences THEN the system always returns null because the token is actually stored in FlutterSecureStorage with key 'jwt_token'

1.3 WHEN multiple feature modules (AuthDependencies, WorkoutDependencies, ProfileDependencies) initialize THEN the system creates separate ApiClient instances instead of using a shared singleton

1.4 WHEN ExercisesScreen and ExerciseSelectionScreen are loaded THEN the system duplicates identical exercise loading, search, and error handling logic violating DRY principles

1.5 WHEN LoginUser use case executes THEN the system makes redundant API calls: first POST /api/auth/login, then GET /api/auth/me (called twice in different places)

1.6 WHEN AuthRepositoryImpl accesses storage THEN the system violates clean architecture by directly importing SharedPreferences in the data layer instead of using proper service abstractions

1.7 WHEN presentation layer screens need user data THEN the system directly accesses SharedPreferences for user_id violating clean architecture separation

1.8 WHEN login_screen.dart is loaded in production THEN the system displays debug UI elements and network diagnostic buttons that should not be visible to end users

1.9 WHEN active_workout_screen.dart uses WillPopScope THEN the system uses deprecated Flutter APIs instead of the current PopScope (Flutter 3.12+)

### Expected Behavior (Correct)

2.1 WHEN the app receives Exercise data from the Java Spring Boot API THEN the system SHALL successfully parse JSON by mapping Java field names `primaryMuscleName`, `equipmentName`, `secondaryMuscleNames` to Flutter field names `primaryMuscle`, `equipment`, `secondaryMuscles`

2.2 WHEN HomeScreen needs JWT token THEN the system SHALL read from FlutterSecureStorage using the correct key 'jwt_token' and return the stored token value

2.3 WHEN multiple feature modules initialize THEN the system SHALL use a single shared ApiClient instance through proper dependency injection

2.4 WHEN ExercisesScreen and ExerciseSelectionScreen need exercise functionality THEN the system SHALL use a shared component/widget that contains the common exercise loading, search, and error handling logic

2.5 WHEN LoginUser use case executes THEN the system SHALL make only the necessary API call POST /api/auth/login and eliminate the redundant GET /api/auth/me calls

2.6 WHEN AuthRepositoryImpl needs storage access THEN the system SHALL use proper service abstractions instead of directly importing infrastructure dependencies

2.7 WHEN presentation layer screens need user data THEN the system SHALL access user information through proper use cases and repositories following clean architecture principles

2.8 WHEN login_screen.dart is loaded in production THEN the system SHALL display only production-ready UI without debug elements or network diagnostic buttons

2.9 WHEN active_workout_screen.dart handles back navigation THEN the system SHALL use PopScope instead of the deprecated WillPopScope API

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the app performs authentication flows THEN the system SHALL CONTINUE TO maintain secure JWT token storage and validation

3.2 WHEN users navigate between screens THEN the system SHALL CONTINUE TO provide smooth navigation and proper state management

3.3 WHEN API calls are made with valid tokens THEN the system SHALL CONTINUE TO successfully authenticate and receive data

3.4 WHEN users interact with exercise lists and workout functionality THEN the system SHALL CONTINUE TO provide the same user experience and functionality

3.5 WHEN the app handles errors and loading states THEN the system SHALL CONTINUE TO display appropriate feedback to users

3.6 WHEN dependency injection is used THEN the system SHALL CONTINUE TO provide proper instance management and lifecycle handling

3.7 WHEN clean architecture layers interact THEN the system SHALL CONTINUE TO maintain proper separation of concerns and testability

3.8 WHEN the app runs on Android and iOS platforms THEN the system SHALL CONTINUE TO function correctly on both target platforms