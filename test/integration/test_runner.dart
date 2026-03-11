import 'package:flutter_test/flutter_test.dart';
import 'end_to_end_flow_test.dart' as end_to_end;
import 'behavior_preservation_test.dart' as behavior;
import 'plate_calculator_test.dart' as plate_calc;

/// Integration Test Runner
///
/// This file runs all integration tests for the Clean Architecture refactor
/// to verify complete user flows work end-to-end and behavior is preserved.
///
/// **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**
void main() {
  group('Complete Integration Test Suite', () {
    group('End-to-End Flow Tests', () {
      end_to_end.main();
    });

    group('Behavior Preservation Tests', () {
      behavior.main();
    });

    group('Plate Calculator Tests', () {
      plate_calc.main();
    });
  });
}
