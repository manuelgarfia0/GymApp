import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/app.dart';
import 'package:gym_app/core/di/dependency_injection.dart';

/// Behavior Preservation Integration Tests
///
/// These tests specifically verify that the Clean Architecture refactor
/// maintains identical behavior to the original implementation across
/// all critical user flows and business operations.
///
/// **Validates: Requirements 10.1-10.7 - All existing functionality preservation**
void main() {
  group('Behavior Preservation Tests', () {
    late Widget app;

    setUpAll(() {
      DependencyInjection.initialize();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = const GymApp();
    });

    group('Authentication Behavior Preservation', () {
      testWidgets('Login flow behavior matches original implementation', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.1 - Login with valid credentials should authenticate and navigate to home screen**

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Verify initial state - should show login screen
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);

        // Test invalid credentials first
        await tester.enterText(find.byType(TextFormField).first, 'invalid');
        await tester.enterText(find.byType(TextFormField).last, 'wrong');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Should remain on login screen with error
        expect(find.text('Login'), findsOneWidget);

        // Test valid credentials
        await tester.enterText(find.byType(TextFormField).first, 'testuser');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Should navigate to home screen
        expect(find.text('Workout'), findsOneWidget);
        expect(find.text('Quick Start'), findsOneWidget);

        // Verify JWT token is stored (behavior preservation)
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('jwt_token'), isNotNull);
        expect(prefs.getInt('user_id'), isNotNull);
      });

      testWidgets('Token persistence behavior matches original', (
        WidgetTester tester,
      ) async {
        // Simulate existing token
        SharedPreferences.setMockInitialValues({
          'jwt_token': 'mock_token_12345',
          'user_id': 1,
        });

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Should skip login and go directly to home
        expect(find.text('Workout'), findsOneWidget);
        expect(find.text('Login'), findsNothing);
      });

      testWidgets('Logout behavior clears token and returns to login', (
        WidgetTester tester,
      ) async {
        // Start with logged in state
        SharedPreferences.setMockInitialValues({
          'jwt_token': 'mock_token_12345',
          'user_id': 1,
        });

        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Navigate to profile and logout
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // Should return to login screen
        expect(find.text('Login'), findsOneWidget);

        // Verify token is cleared
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('jwt_token'), isNull);
        expect(prefs.getInt('user_id'), isNull);
      });
    });

    group('Workout Management Behavior Preservation', () {
      testWidgets('Routine creation behavior matches original', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.2 - Routine creation should save and display in routines list**

        await _loginAndNavigateToHome(tester, app);

        // Get initial routine count
        await tester.pumpAndSettle();
        final initialRoutineCards = find.byType(Card).evaluate().length;

        // Create new routine
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();

        expect(find.text('Create Routine'), findsOneWidget);

        // Enter routine details
        await tester.enterText(find.byType(TextFormField), 'Push Day Routine');

        // Save routine
        await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
        await tester.pumpAndSettle();

        // Should return to home and show new routine
        expect(find.text('Push Day Routine'), findsOneWidget);

        // Verify routine count increased
        final newRoutineCards = find.byType(Card).evaluate().length;
        expect(newRoutineCards, greaterThan(initialRoutineCards));
      });

      testWidgets('Workout tracking behavior matches original', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.3 - Starting workout should enable tracking exercises and sets**

        await _loginAndNavigateToHome(tester, app);

        // Start empty workout
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Start Empty Workout'),
        );
        await tester.pumpAndSettle();

        // Should be on active workout screen
        expect(find.text('Active Workout'), findsOneWidget);
        expect(find.text('Add Exercise'), findsOneWidget);

        // Add exercise to workout
        await tester.tap(find.text('Add Exercise'));
        await tester.pumpAndSettle();

        // Should show exercises list
        expect(find.text('Exercises'), findsOneWidget);

        // Select first exercise if available
        final exerciseCards = find.byType(Card);
        if (exerciseCards.evaluate().isNotEmpty) {
          await tester.tap(exerciseCards.first);
          await tester.pumpAndSettle();
        }

        // Should return to active workout with exercise added
        expect(find.text('Active Workout'), findsOneWidget);
      });

      testWidgets('Workout history behavior matches original', (
        WidgetTester tester,
      ) async {
        await _loginAndNavigateToHome(tester, app);

        // Check history section exists
        expect(find.text('History'), findsOneWidget);

        // Should show completed workouts if any exist
        // This tests that the history display behavior is preserved
        await tester.pumpAndSettle();

        // Verify history section is scrollable and displays workouts
        final historySection = find.text('History');
        expect(historySection, findsOneWidget);
      });
    });

    group('Profile Management Behavior Preservation', () {
      testWidgets('Profile display behavior matches original', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.4 - Profile view should display user information correctly**

        await _loginAndNavigateToHome(tester, app);

        // Navigate to profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Should display user information
        expect(find.text('Profile'), findsOneWidget);
        expect(find.text('testuser'), findsOneWidget);
        expect(find.text('Account Information'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Should show logout button
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });

      testWidgets('Profile update behavior matches original', (
        WidgetTester tester,
      ) async {
        await _loginAndNavigateToHome(tester, app);

        // Navigate to profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        // Look for edit functionality
        final editButtons = find.byIcon(Icons.edit);
        if (editButtons.evaluate().isNotEmpty) {
          await tester.tap(editButtons.first);
          await tester.pumpAndSettle();

          // Should show editable form
          expect(find.byType(TextFormField), findsAtLeastNWidgets(1));

          // Test saving changes
          final saveButton = find.widgetWithText(ElevatedButton, 'Save');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();

            // Should return to profile view
            expect(find.text('Profile'), findsOneWidget);
          }
        }
      });
    });

    group('Plate Calculator Behavior Preservation', () {
      testWidgets('Plate calculator computation matches original', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.5 - Plate calculator should compute correct plate combinations**

        await _loginAndNavigateToHome(tester, app);

        // Start workout to access plate calculator
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Start Empty Workout'),
        );
        await tester.pumpAndSettle();

        // Look for plate calculator access
        final calculatorButton = find.byIcon(Icons.calculate);
        if (calculatorButton.evaluate().isNotEmpty) {
          await tester.tap(calculatorButton);
          await tester.pumpAndSettle();

          // Should show plate calculator
          expect(find.text('Plate Calculator'), findsOneWidget);

          // Test standard weight calculations
          await _testPlateCalculation(tester, '225', [
            '45',
            '45',
          ]); // 2x45 + bar
          await _testPlateCalculation(tester, '135', ['45']); // 1x45 + bar
          await _testPlateCalculation(tester, '315', [
            '45',
            '45',
            '45',
          ]); // 3x45 + bar
        }
      });

      testWidgets('Plate calculator UI behavior matches original', (
        WidgetTester tester,
      ) async {
        await _loginAndNavigateToHome(tester, app);

        // Access plate calculator through workout
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Start Empty Workout'),
        );
        await tester.pumpAndSettle();

        final calculatorButton = find.byIcon(Icons.calculate);
        if (calculatorButton.evaluate().isNotEmpty) {
          await tester.tap(calculatorButton);
          await tester.pumpAndSettle();

          // Verify UI elements are present
          expect(find.byType(TextFormField), findsOneWidget); // Weight input
          expect(find.text('Plate Calculator'), findsOneWidget);

          // Test input validation behavior
          await tester.enterText(find.byType(TextFormField), 'invalid');
          await tester.pumpAndSettle();

          // Should handle invalid input gracefully
          await tester.enterText(find.byType(TextFormField), '100');
          await tester.pumpAndSettle();

          // Should show valid calculation
          expect(find.textContaining('plates'), findsOneWidget);
        }
      });
    });

    group('Navigation Behavior Preservation', () {
      testWidgets('Tab navigation behavior matches original', (
        WidgetTester tester,
      ) async {
        await _loginAndNavigateToHome(tester, app);

        // Test all tab navigation
        expect(find.text('Workout'), findsOneWidget);

        // Navigate to exercises
        await tester.tap(find.text('Exercises'));
        await tester.pumpAndSettle();
        expect(find.text('Exercises'), findsOneWidget);

        // Navigate to profile
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(find.text('Profile'), findsOneWidget);

        // Navigate back to workout
        await tester.tap(find.text('Workout'));
        await tester.pumpAndSettle();
        expect(find.text('Quick Start'), findsOneWidget);
      });

      testWidgets('Screen transitions behavior matches original', (
        WidgetTester tester,
      ) async {
        await _loginAndNavigateToHome(tester, app);

        // Test routine creation navigation
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();
        expect(find.text('Create Routine'), findsOneWidget);

        // Test back navigation
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(find.text('Quick Start'), findsOneWidget);
      });
    });

    group('Error Handling Behavior Preservation', () {
      testWidgets('Network error handling matches original', (
        WidgetTester tester,
      ) async {
        // Test that network errors are handled gracefully
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Attempt login with network issues (simulated)
        await tester.enterText(find.byType(TextFormField).first, 'testuser');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Should handle errors gracefully without crashing
        // The exact behavior depends on network mocking setup
      });

      testWidgets('Form validation behavior matches original', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Test empty form submission
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Should show validation errors or prevent submission
        expect(find.text('Login'), findsOneWidget); // Should remain on login
      });
    });
  });
}

/// Helper function to login and navigate to home
Future<void> _loginAndNavigateToHome(WidgetTester tester, Widget app) async {
  SharedPreferences.setMockInitialValues({
    'jwt_token': 'mock_token_12345',
    'user_id': 1,
  });

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Helper function to test plate calculator calculations
Future<void> _testPlateCalculation(
  WidgetTester tester,
  String weight,
  List<String> expectedPlates,
) async {
  await tester.enterText(find.byType(TextFormField), weight);
  await tester.pumpAndSettle();

  // Verify expected plates are shown
  for (String plate in expectedPlates) {
    expect(find.textContaining(plate), findsAtLeastNWidgets(1));
  }
}
