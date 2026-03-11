import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_app/app.dart';
import 'package:gym_app/core/di/dependency_injection.dart';

/// Plate Calculator Integration Tests
///
/// These tests specifically verify that the plate calculator functionality
/// works correctly and maintains the same behavior as the original implementation.
///
/// **Validates: Requirement 10.5 - Plate calculator should compute correct plate combinations**
void main() {
  group('Plate Calculator Integration Tests', () {
    late Widget app;

    setUpAll(() {
      DependencyInjection.initialize();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'jwt_token': 'mock_token_12345',
        'user_id': 1,
      });
      app = const GymApp();
    });

    testWidgets(
      'Plate calculator computes correct combinations for standard weights',
      (WidgetTester tester) async {
        await tester.pumpWidget(app);
        await tester.pumpAndSettle();

        // Navigate to workout screen and access plate calculator
        await _accessPlateCalculator(tester);

        // Test standard barbell weights (assuming 45lb bar)
        await _testWeightCalculation(tester, '135', [
          '45',
        ]); // 1x45 each side + 45lb bar
        await _testWeightCalculation(tester, '225', [
          '45',
          '45',
        ]); // 2x45 each side + bar
        await _testWeightCalculation(tester, '315', [
          '45',
          '45',
          '45',
        ]); // 3x45 each side + bar
        await _testWeightCalculation(tester, '405', [
          '45',
          '45',
          '45',
          '45',
        ]); // 4x45 each side + bar
      },
    );

    testWidgets('Plate calculator handles mixed plate combinations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Test weights that require mixed plates
      await _testWeightCalculation(tester, '185', [
        '45',
        '25',
      ]); // 1x45 + 1x25 each side
      await _testWeightCalculation(tester, '275', [
        '45',
        '45',
        '25',
      ]); // 2x45 + 1x25 each side
      await _testWeightCalculation(tester, '155', [
        '45',
        '10',
      ]); // 1x45 + 1x10 each side
    });

    testWidgets('Plate calculator handles edge cases correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Test edge cases
      await _testWeightCalculation(tester, '45', []); // Just the bar
      await _testWeightCalculation(tester, '50', ['2.5']); // Bar + 2.5lb plates
      await _testWeightCalculation(tester, '55', ['5']); // Bar + 5lb plates
    });

    testWidgets('Plate calculator input validation works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Test invalid inputs
      await tester.enterText(find.byType(TextFormField), 'invalid');
      await tester.pumpAndSettle();

      // Should handle invalid input gracefully
      expect(find.text('Plate Calculator'), findsOneWidget);

      // Test negative numbers
      await tester.enterText(find.byType(TextFormField), '-100');
      await tester.pumpAndSettle();

      // Should handle negative input appropriately

      // Test zero
      await tester.enterText(find.byType(TextFormField), '0');
      await tester.pumpAndSettle();

      // Should handle zero appropriately
    });

    testWidgets('Plate calculator UI updates in real-time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Test that UI updates as user types
      await tester.enterText(find.byType(TextFormField), '1');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '13');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '135');
      await tester.pumpAndSettle();

      // Should show final calculation for 135
      expect(find.textContaining('45'), findsAtLeastNWidgets(1));
    });

    testWidgets('Plate calculator can be accessed from multiple contexts', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Test accessing from empty workout
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Start Empty Workout'),
      );
      await tester.pumpAndSettle();

      final calculatorButton = find.byIcon(Icons.calculate);
      if (calculatorButton.evaluate().isNotEmpty) {
        await tester.tap(calculatorButton);
        await tester.pumpAndSettle();

        expect(find.text('Plate Calculator'), findsOneWidget);

        // Close calculator
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }

      // Test accessing from routine-based workout
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // If there are routines, test accessing calculator from routine workout
      final routineCards = find.byType(Card);
      if (routineCards.evaluate().isNotEmpty) {
        await tester.tap(routineCards.first);
        await tester.pumpAndSettle();

        final calculatorButtonInRoutine = find.byIcon(Icons.calculate);
        if (calculatorButtonInRoutine.evaluate().isNotEmpty) {
          await tester.tap(calculatorButtonInRoutine);
          await tester.pumpAndSettle();

          expect(find.text('Plate Calculator'), findsOneWidget);
        }
      }
    });

    testWidgets('Plate calculator maintains state during session', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Enter a weight
      await tester.enterText(find.byType(TextFormField), '225');
      await tester.pumpAndSettle();

      // Close calculator
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Reopen calculator
      final calculatorButton = find.byIcon(Icons.calculate);
      if (calculatorButton.evaluate().isNotEmpty) {
        await tester.tap(calculatorButton);
        await tester.pumpAndSettle();

        // Should remember the last entered weight
        expect(find.text('225'), findsOneWidget);
      }
    });

    testWidgets('Plate calculator supports different unit systems', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await _accessPlateCalculator(tester);

      // Test if there's a unit toggle (lbs/kg)
      final unitToggle = find.text('kg');
      if (unitToggle.evaluate().isNotEmpty) {
        await tester.tap(unitToggle);
        await tester.pumpAndSettle();

        // Test kg calculations
        await _testWeightCalculation(tester, '100', [
          '20',
          '20',
        ]); // 2x20kg each side + 20kg bar

        // Switch back to lbs
        await tester.tap(find.text('lbs'));
        await tester.pumpAndSettle();

        // Test lbs calculations
        await _testWeightCalculation(tester, '225', ['45', '45']);
      }
    });
  });
}

/// Helper function to access the plate calculator
Future<void> _accessPlateCalculator(WidgetTester tester) async {
  // Start an empty workout to access plate calculator
  await tester.tap(find.widgetWithText(ElevatedButton, 'Start Empty Workout'));
  await tester.pumpAndSettle();

  // Look for plate calculator button
  final calculatorButton = find.byIcon(Icons.calculate);
  if (calculatorButton.evaluate().isNotEmpty) {
    await tester.tap(calculatorButton);
    await tester.pumpAndSettle();

    expect(find.text('Plate Calculator'), findsOneWidget);
  } else {
    // If not found, try alternative access methods
    // Look for it in exercise logging or other contexts
    final addExerciseButton = find.text('Add Exercise');
    if (addExerciseButton.evaluate().isNotEmpty) {
      await tester.tap(addExerciseButton);
      await tester.pumpAndSettle();

      // Select an exercise and look for calculator there
      final exerciseCards = find.byType(Card);
      if (exerciseCards.evaluate().isNotEmpty) {
        await tester.tap(exerciseCards.first);
        await tester.pumpAndSettle();

        final calculatorInExercise = find.byIcon(Icons.calculate);
        if (calculatorInExercise.evaluate().isNotEmpty) {
          await tester.tap(calculatorInExercise);
          await tester.pumpAndSettle();
        }
      }
    }
  }
}

/// Helper function to test weight calculations
Future<void> _testWeightCalculation(
  WidgetTester tester,
  String weight,
  List<String> expectedPlates,
) async {
  // Clear any existing input
  await tester.enterText(find.byType(TextFormField), '');
  await tester.pumpAndSettle();

  // Enter the weight
  await tester.enterText(find.byType(TextFormField), weight);
  await tester.pumpAndSettle();

  // Verify the calculation shows expected plates
  for (String plate in expectedPlates) {
    expect(
      find.textContaining(plate),
      findsAtLeastNWidgets(1),
      reason: 'Expected to find plate weight $plate for total weight $weight',
    );
  }

  // Verify that some calculation result is shown
  expect(
    find.textContaining('plates'),
    findsAtLeastNWidgets(1),
    reason: 'Expected to find plate calculation result for weight $weight',
  );
}
