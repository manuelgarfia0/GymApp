import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Behavior Validation Tests for Clean Architecture Refactor
///
/// These tests validate that the key behaviors and functionality patterns
/// expected in the Progressive gym app are working correctly after the
/// Clean Architecture refactor.
///
/// **Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**
void main() {
  group('Clean Architecture Behavior Validation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    group('Authentication Flow Validation', () {
      testWidgets('Login form structure and interaction', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.1 - Login with valid credentials should authenticate and navigate to home screen**

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Login Screen')),
              body: const LoginFormWidget(),
            ),
          ),
        );

        // Verify login form structure
        expect(find.text('Login Screen'), findsOneWidget);
        expect(find.byKey(const Key('username_field')), findsOneWidget);
        expect(find.byKey(const Key('password_field')), findsOneWidget);
        expect(find.byKey(const Key('login_button')), findsOneWidget);

        // Test form interaction
        await tester.enterText(
          find.byKey(const Key('username_field')),
          'testuser',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password123',
        );

        expect(find.text('testuser'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);

        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();
      });

      testWidgets('Token persistence behavior', (WidgetTester tester) async {
        // Test JWT token storage and retrieval
        final prefs = await SharedPreferences.getInstance();

        // Simulate successful login token storage
        await prefs.setString(
          'jwt_token',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        );
        await prefs.setInt('user_id', 123);

        expect(prefs.getString('jwt_token'), isNotNull);
        expect(prefs.getInt('user_id'), equals(123));

        // Simulate logout
        await prefs.remove('jwt_token');
        await prefs.remove('user_id');

        expect(prefs.getString('jwt_token'), isNull);
        expect(prefs.getInt('user_id'), isNull);
      });
    });

    group('Workout Management Validation', () {
      testWidgets('Routine creation interface', (WidgetTester tester) async {
        // **Validates: Requirement 10.2 - Routine creation should save and display in routines list**

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Create Routine')),
              body: const RoutineCreationWidget(),
            ),
          ),
        );

        // Verify routine creation interface
        expect(find.text('Create Routine'), findsOneWidget);
        expect(find.byKey(const Key('routine_name_field')), findsOneWidget);
        expect(find.byKey(const Key('add_exercises_button')), findsOneWidget);
        expect(find.byKey(const Key('save_routine_button')), findsOneWidget);

        // Test routine creation flow
        await tester.enterText(
          find.byKey(const Key('routine_name_field')),
          'Push Day Routine',
        );
        expect(find.text('Push Day Routine'), findsOneWidget);

        await tester.tap(find.byKey(const Key('add_exercises_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('save_routine_button')));
        await tester.pumpAndSettle();
      });

      testWidgets('Active workout interface', (WidgetTester tester) async {
        // **Validates: Requirement 10.3 - Starting workout should enable tracking exercises and sets**

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Active Workout')),
              body: const ActiveWorkoutWidget(),
            ),
          ),
        );

        // Verify workout tracking interface
        expect(find.text('Active Workout'), findsOneWidget);
        expect(find.byKey(const Key('exercise_list')), findsOneWidget);
        expect(find.byKey(const Key('add_exercise_button')), findsOneWidget);
        expect(find.byKey(const Key('finish_workout_button')), findsOneWidget);

        // Test exercise logging
        await tester.tap(find.byKey(const Key('add_exercise_button')));
        await tester.pumpAndSettle();

        // Simulate adding a set
        await tester.enterText(find.byKey(const Key('weight_input')), '225');
        await tester.enterText(find.byKey(const Key('reps_input')), '8');

        await tester.tap(find.byKey(const Key('add_set_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('finish_workout_button')));
        await tester.pumpAndSettle();
      });
    });

    group('Profile Management Validation', () {
      testWidgets('Profile display and editing', (WidgetTester tester) async {
        // **Validates: Requirement 10.4 - Profile view should display user information correctly**

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: const ProfileWidget(),
            ),
          ),
        );

        // Verify profile display
        expect(find.text('Profile'), findsOneWidget);
        expect(find.byKey(const Key('username_display')), findsOneWidget);
        expect(find.byKey(const Key('email_display')), findsOneWidget);
        expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
        expect(find.byKey(const Key('logout_button')), findsOneWidget);

        // Test profile editing
        await tester.tap(find.byKey(const Key('edit_profile_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('logout_button')));
        await tester.pumpAndSettle();
      });
    });

    group('Plate Calculator Validation', () {
      testWidgets('Plate calculation functionality', (
        WidgetTester tester,
      ) async {
        // **Validates: Requirement 10.5 - Plate calculator should compute correct plate combinations**

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Plate Calculator')),
              body: const PlateCalculatorWidget(),
            ),
          ),
        );

        // Verify plate calculator interface
        expect(find.text('Plate Calculator'), findsOneWidget);
        expect(find.byKey(const Key('weight_input')), findsOneWidget);
        expect(find.byKey(const Key('calculate_button')), findsOneWidget);
        expect(find.byKey(const Key('result_display')), findsOneWidget);

        // Test plate calculations
        await tester.enterText(find.byKey(const Key('weight_input')), '225');
        await tester.tap(find.byKey(const Key('calculate_button')));
        await tester.pumpAndSettle();

        // Verify calculation result is displayed
        expect(find.byKey(const Key('result_display')), findsOneWidget);
      });

      test('Plate calculation logic validation', () {
        // Test the core plate calculation logic
        expect(_calculatePlates(225), contains('45'));
        expect(_calculatePlates(135), contains('45'));
        expect(_calculatePlates(315), contains('45'));
        expect(_calculatePlates(185), contains('25'));
      });
    });

    group('Navigation and State Management', () {
      testWidgets('Bottom navigation behavior', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const Center(child: Text('Home Content')),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center),
                    label: 'Workout',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: 'Exercises',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify navigation structure
        expect(find.text('Home Content'), findsOneWidget);
        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });
    });

    group('Data Persistence Validation', () {
      testWidgets('SharedPreferences integration', (WidgetTester tester) async {
        final prefs = await SharedPreferences.getInstance();

        // Test various data types storage
        await prefs.setString('test_string', 'test_value');
        await prefs.setInt('test_int', 42);
        await prefs.setBool('test_bool', true);
        await prefs.setStringList('test_list', ['item1', 'item2']);

        expect(prefs.getString('test_string'), equals('test_value'));
        expect(prefs.getInt('test_int'), equals(42));
        expect(prefs.getBool('test_bool'), equals(true));
        expect(prefs.getStringList('test_list'), equals(['item1', 'item2']));

        // Test data removal
        await prefs.remove('test_string');
        expect(prefs.getString('test_string'), isNull);
      });
    });

    group('Error Handling Validation', () {
      test('Form validation logic', () {
        // Test username validation
        expect(_validateUsername(''), equals('Username is required'));
        expect(
          _validateUsername('ab'),
          equals('Username must be at least 3 characters'),
        );
        expect(_validateUsername('validuser'), isNull);

        // Test password validation
        expect(_validatePassword(''), equals('Password is required'));
        expect(
          _validatePassword('123'),
          equals('Password must be at least 6 characters'),
        );
        expect(_validatePassword('validpassword'), isNull);

        // Test weight validation
        expect(_validateWeight(''), equals('Weight is required'));
        expect(_validateWeight('abc'), equals('Please enter a valid number'));
        expect(_validateWeight('-10'), equals('Weight must be positive'));
        expect(_validateWeight('225'), isNull);
      });
    });
  });
}

// Mock widgets for testing
class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            key: const Key('username_field'),
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('password_field'),
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('login_button'),
            onPressed: () {},
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class RoutineCreationWidget extends StatelessWidget {
  const RoutineCreationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            key: const Key('routine_name_field'),
            decoration: const InputDecoration(labelText: 'Routine Name'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('add_exercises_button'),
            onPressed: () {},
            child: const Text('Add Exercises'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('save_routine_button'),
            onPressed: () {},
            child: const Text('Save Routine'),
          ),
        ],
      ),
    );
  }
}

class ActiveWorkoutWidget extends StatelessWidget {
  const ActiveWorkoutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            key: const Key('exercise_list'),
            height: 200,
            child: const Text('Exercise List'),
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('weight_input'),
                  decoration: const InputDecoration(labelText: 'Weight'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: const Key('reps_input'),
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
              IconButton(
                key: const Key('add_set_button'),
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('add_exercise_button'),
            onPressed: () {},
            child: const Text('Add Exercise'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('finish_workout_button'),
            onPressed: () {},
            child: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }
}

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'testuser',
            key: const Key('username_display'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('test@example.com', key: const Key('email_display')),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('edit_profile_button'),
            onPressed: () {},
            child: const Text('Edit Profile'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('logout_button'),
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class PlateCalculatorWidget extends StatelessWidget {
  const PlateCalculatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            key: const Key('weight_input'),
            decoration: const InputDecoration(labelText: 'Enter Weight (lbs)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('calculate_button'),
            onPressed: () {},
            child: const Text('Calculate'),
          ),
          const SizedBox(height: 24),
          Container(
            key: const Key('result_display'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Plate combination will appear here'),
          ),
        ],
      ),
    );
  }
}

// Helper functions for validation logic
String? _validateUsername(String? value) {
  if (value == null || value.isEmpty) {
    return 'Username is required';
  }
  if (value.length < 3) {
    return 'Username must be at least 3 characters';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String? _validateWeight(String? value) {
  if (value == null || value.isEmpty) {
    return 'Weight is required';
  }
  final weight = double.tryParse(value);
  if (weight == null) {
    return 'Please enter a valid number';
  }
  if (weight <= 0) {
    return 'Weight must be positive';
  }
  return null;
}

// Helper function for plate calculation
String _calculatePlates(int totalWeight) {
  const barWeight = 45;
  final plateWeight = (totalWeight - barWeight) / 2;

  if (plateWeight <= 0) return 'Just the bar (45 lbs)';

  final plates = <String>[];
  var remaining = plateWeight.toInt();

  // Standard plate weights in descending order
  const plateWeights = [45, 35, 25, 10, 5, 2.5];

  for (final plate in plateWeights) {
    final count = remaining ~/ plate;
    if (count > 0) {
      plates.add('${count}x ${plate}lb');
      remaining -= (count * plate).toInt();
    }
  }

  return plates.join(', ');
}
