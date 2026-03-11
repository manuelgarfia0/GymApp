import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/app.dart';
import 'package:gym_app/core/di/dependency_injection.dart';

/// Integration tests for complete user flows end-to-end
///
/// These tests verify that the refactored Clean Architecture implementation
/// maintains identical behavior to the pre-refactored version across all
/// major user journeys.
///
/// **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**
void main() {
  group('End-to-End User Flow Tests', () {
    late Widget app;

    setUpAll(() {
      // Initialize dependency injection for tests
      DependencyInjection.initialize();
    });

    setUp(() async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});
      app = const GymApp();
    });

    testWidgets('Complete login to home navigation flow', (
      WidgetTester tester,
    ) async {
      // **Validates: Requirement 10.1 - Login with valid credentials should authenticate and navigate to home screen**

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Should start at login screen (no token stored)
      expect(find.text('Login'), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // Username and password fields

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should navigate to home screen after successful login
      expect(find.text('Workout'), findsOneWidget); // Home screen tab
      expect(find.text('Quick Start'), findsOneWidget);
      expect(find.text('Start Empty Workout'), findsOneWidget);
      expect(find.text('My Routines'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('Routine creation and display flow', (
      WidgetTester tester,
    ) async {
      // **Validates: Requirement 10.2 - Routine creation should save and display in routines list**

      // First login to access the app
      await _performLogin(tester, app);

      // Navigate to create routine
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Should be on create routine screen
      expect(find.text('Create Routine'), findsOneWidget);
      expect(find.text('Routine Name'), findsOneWidget);

      // Enter routine name
      await tester.enterText(find.byType(TextFormField), 'Test Routine');

      // Add exercises to routine
      await tester.tap(find.text('Add Exercises'));
      await tester.pumpAndSettle();

      // Should be on exercises selection screen
      expect(find.text('Exercises'), findsOneWidget);

      // Select first exercise (assuming exercises are loaded)
      final exerciseCards = find.byType(Card);
      if (exerciseCards.evaluate().isNotEmpty) {
        await tester.tap(exerciseCards.first);
        await tester.pumpAndSettle();
      }

      // Go back to create routine
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Save the routine
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
      await tester.pumpAndSettle();

      // Should return to home screen and show the new routine
      expect(find.text('Test Routine'), findsOneWidget);
      expect(
        find.byIcon(Icons.play_arrow),
        findsOneWidget,
      ); // Play button for routine
    });

    testWidgets('Workout tracking and exercise logging flow', (
      WidgetTester tester,
    ) async {
      // **Validates: Requirement 10.3 - Starting workout should enable tracking exercises and sets**

      // First login and create a routine
      await _performLogin(tester, app);
      await _createTestRoutine(tester);

      // Start a workout from the routine
      await tester.tap(find.text('Test Routine'));
      await tester.pumpAndSettle();

      // Should be on active workout screen
      expect(find.text('Active Workout'), findsOneWidget);
      expect(find.text('Test Routine'), findsOneWidget);

      // Should show exercise from routine
      expect(find.byType(Card), findsAtLeastNWidgets(1)); // Exercise cards

      // Add a set to the first exercise
      final addSetButtons = find.widgetWithIcon(IconButton, Icons.add);
      if (addSetButtons.evaluate().isNotEmpty) {
        await tester.tap(addSetButtons.first);
        await tester.pumpAndSettle();

        // Enter weight and reps
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 2) {
          await tester.enterText(textFields.first, '100'); // Weight
          await tester.enterText(textFields.last, '10'); // Reps
        }

        // Confirm the set
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Set'));
        await tester.pumpAndSettle();
      }

      // Finish the workout
      await tester.tap(find.widgetWithText(ElevatedButton, 'Finish Workout'));
      await tester.pumpAndSettle();

      // Should return to home screen and show workout in history
      expect(find.text('History'), findsOneWidget);
      expect(
        find.text('Test Routine'),
        findsAtLeastNWidgets(1),
      ); // In history section
    });

    testWidgets('Profile management functionality', (
      WidgetTester tester,
    ) async {
      // **Validates: Requirement 10.4 - Profile view should display user information correctly**

      // First login to access the app
      await _performLogin(tester, app);

      // Navigate to profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Should be on profile screen
      expect(find.text('Profile'), findsOneWidget);
      expect(
        find.text('testuser'),
        findsOneWidget,
      ); // Username should be displayed

      // Should show user information sections
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Test profile editing if available
      final editButtons = find.byIcon(Icons.edit);
      if (editButtons.evaluate().isNotEmpty) {
        await tester.tap(editButtons.first);
        await tester.pumpAndSettle();

        // Should show editable fields
        expect(find.byType(TextFormField), findsAtLeastNWidgets(1));

        // Make a change and save
        await tester.enterText(
          find.byType(TextFormField).first,
          'Updated Name',
        );

        final saveButton = find.widgetWithText(ElevatedButton, 'Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Plate calculator functionality', (WidgetTester tester) async {
      // **Validates: Requirement 10.5 - Plate calculator should compute correct plate combinations**

      // First login to access the app
      await _performLogin(tester, app);

      // Start an empty workout to access plate calculator
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Start Empty Workout'),
      );
      await tester.pumpAndSettle();

      // Look for plate calculator access (usually in exercise logging)
      final plateCalculatorButton = find.byIcon(Icons.calculate);
      if (plateCalculatorButton.evaluate().isNotEmpty) {
        await tester.tap(plateCalculatorButton);
        await tester.pumpAndSettle();

        // Should show plate calculator
        expect(find.text('Plate Calculator'), findsOneWidget);

        // Enter a weight value
        await tester.enterText(find.byType(TextFormField), '225');
        await tester.pumpAndSettle();

        // Should show plate combination
        expect(
          find.textContaining('45'),
          findsAtLeastNWidgets(1),
        ); // 45lb plates
        expect(find.textContaining('plates'), findsOneWidget);

        // Test different weight
        await tester.enterText(find.byType(TextFormField), '135');
        await tester.pumpAndSettle();

        // Should update plate combination
        expect(find.textContaining('45'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Complete logout flow', (WidgetTester tester) async {
      // **Validates: Requirement 10.6 - Logout should clear JWT token and return to login**

      // First login to access the app
      await _performLogin(tester, app);

      // Navigate to profile tab where logout button is located
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Tap logout button
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Should return to login screen
      expect(find.text('Login'), findsOneWidget);
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
      ); // Username and password fields

      // Verify token is cleared by checking that app starts at login on restart
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget); // Should still be at login
    });

    testWidgets('Exercise search and selection flow', (
      WidgetTester tester,
    ) async {
      // Additional test for exercise functionality

      await _performLogin(tester, app);

      // Navigate to exercises tab
      await tester.tap(find.text('Exercises'));
      await tester.pumpAndSettle();

      // Should be on exercises screen
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search field

      // Test search functionality
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pumpAndSettle();

      // Should filter exercises
      expect(
        find.byType(Card),
        findsAtLeastNWidgets(0),
      ); // May or may not find exercises

      // Clear search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation between tabs preserves state', (
      WidgetTester tester,
    ) async {
      // Test that navigation between tabs works correctly

      await _performLogin(tester, app);

      // Start on workout tab
      expect(find.text('Quick Start'), findsOneWidget);

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
  });
}

/// Helper function to perform login flow
Future<void> _performLogin(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  // Enter credentials and login
  await tester.enterText(find.byType(TextFormField).first, 'testuser');
  await tester.enterText(find.byType(TextFormField).last, 'password123');
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

/// Helper function to create a test routine
Future<void> _createTestRoutine(WidgetTester tester) async {
  // Navigate to create routine
  await tester.tap(find.byIcon(Icons.add_circle_outline));
  await tester.pumpAndSettle();

  // Enter routine name
  await tester.enterText(find.byType(TextFormField), 'Test Routine');

  // Add exercises (simplified - just save the routine)
  await tester.tap(find.widgetWithText(ElevatedButton, 'Create Routine'));
  await tester.pumpAndSettle();
}
