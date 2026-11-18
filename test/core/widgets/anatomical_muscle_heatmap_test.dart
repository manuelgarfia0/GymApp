import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/anatomical_muscle_heatmap.dart';
import 'package:gym_app/features/workouts/domain/entities/exercise.dart';
import 'package:gym_app/features/workouts/domain/entities/muscle_heatmap.dart';
import 'package:gym_app/features/workouts/domain/entities/workout.dart';
import 'package:gym_app/features/workouts/domain/use_cases/calculate_muscle_heatmap.dart';

void main() {
  const calculator = CalculateMuscleHeatmap();
  const benchPress = Exercise(
    id: 1,
    name: 'Bench Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: ['Triceps', 'Shoulders'],
  );
  const barbellRow = Exercise(
    id: 2,
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    secondaryMuscles: ['Biceps', 'Traps'],
  );

  final exercisesById = {1: benchPress, 2: barbellRow};

  Map<MuscleHeatmapRange, MuscleHeatmapData> buildSampleHeatmaps() {
    final reference = DateTime(2026, 11, 18);
    final workouts = [
      Workout(
        id: 1,
        name: 'Old Push',
        startTime: DateTime(2026, 11, 2, 18, 0),
        endTime: DateTime(2026, 11, 2, 19, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            exerciseOrder: 1,
            setNumber: 1,
            weight: 80,
            reps: 10,
            timestamp: DateTime(2026, 11, 2, 18, 10),
            isCompleted: true,
          ),
        ],
      ),
      Workout(
        id: 2,
        name: 'Recent Pull',
        startTime: DateTime(2026, 11, 17, 18, 0),
        endTime: DateTime(2026, 11, 17, 19, 0),
        userId: 1,
        sets: [
          WorkoutSet(
            exerciseId: 2,
            exerciseName: 'Barbell Row',
            exerciseOrder: 1,
            setNumber: 1,
            weight: 75,
            reps: 8,
            timestamp: DateTime(2026, 11, 17, 18, 10),
            isCompleted: true,
          ),
        ],
      ),
    ];

    return {
      for (final range in MuscleHeatmapRange.values)
        range: calculator(
          workouts: workouts,
          exercisesById: exercisesById,
          range: range,
          referenceDate: reference,
        ),
    };
  }

  group('AnatomicalMuscleHeatmap', () {
    testWidgets('renders front/back figures, switches ranges, and shows muscle details on selection', (tester) async {
      final heatmaps = buildSampleHeatmaps();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnatomicalMuscleHeatmap(heatmapsByRange: heatmaps),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FRONTAL'), findsOneWidget);
      expect(find.text('ESPALDA'), findsOneWidget);
      expect(find.byKey(const Key('muscle_canvas_front')), findsOneWidget);
      expect(find.byKey(const Key('muscle_canvas_back')), findsOneWidget);

      // Default range is 30 días, containing both Chest and Back
      expect(find.byKey(const Key('muscle_chip_chest')), findsOneWidget);
      expect(find.byKey(const Key('muscle_chip_back')), findsOneWidget);

      // Select Chest chip and verify detailed breakdown appears
      await tester.ensureVisible(find.byKey(const Key('muscle_chip_chest')));
      await tester.tap(find.byKey(const Key('muscle_chip_chest')));
      await tester.pumpAndSettle();

      final detailPanel = find.byKey(const Key('muscle_detail_panel'));
      expect(detailPanel, findsOneWidget);
      expect(
        find.descendant(of: detailPanel, matching: find.text('Pecho')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detailPanel, matching: find.text('Bench Press')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detailPanel,
          matching: find.textContaining('800 kg'),
        ),
        findsOneWidget,
      );

      // Switch to 7 días: old Chest workout disappears, Back remains
      await tester.ensureVisible(find.byKey(const Key('muscle_range_last7Days')));
      await tester.tap(find.byKey(const Key('muscle_range_last7Days')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('muscle_chip_chest')), findsNothing);
      expect(find.byKey(const Key('muscle_chip_back')), findsOneWidget);
    });

    testWidgets('supports direct tap on anatomical front body canvas', (tester) async {
      final heatmaps = buildSampleHeatmaps();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnatomicalMuscleHeatmap(heatmapsByRange: heatmaps),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final frontCanvas = find.byKey(const Key('muscle_canvas_front'));
      final topLeft = tester.getTopLeft(frontCanvas);
      final size = tester.getSize(frontCanvas);

      // In normalized 200x420 coordinates, chest sits around (118, 100).
      final scale = (size.width / 200.0) < (size.height / 420.0)
          ? size.width / 200.0
          : size.height / 420.0;
      final offsetX = (size.width - 200.0 * scale) / 2.0;
      final offsetY = (size.height - 420.0 * scale) / 2.0;
      final chestTap = Offset(
        topLeft.dx + offsetX + 118.0 * scale,
        topLeft.dy + offsetY + 100.0 * scale,
      );

      await tester.tapAt(chestTap);
      await tester.pumpAndSettle();

      final detailPanel = find.byKey(const Key('muscle_detail_panel'));
      expect(
        find.descendant(of: detailPanel, matching: find.text('Pecho')),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state cleanly without overflow or errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnatomicalMuscleHeatmap(
                singleData: MuscleHeatmapData.empty,
                subtitle: 'Vista previa',
                compact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vista previa'), findsOneWidget);
      expect(find.text('Sin entrenamientos en este periodo'), findsOneWidget);
    });
  });
}
