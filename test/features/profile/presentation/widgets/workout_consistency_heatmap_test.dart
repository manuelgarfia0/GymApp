import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/profile/domain/use_cases/get_user_stats.dart';
import 'package:gym_app/features/profile/presentation/widgets/workout_consistency_heatmap.dart';

void main() {
  group('WorkoutConsistencyHeatmap', () {
    test('intensityLevelForVolume scales across buckets 0..4', () {
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(0, 1000),
        0,
      );
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(
          0,
          1000,
          hasWorkout: true,
        ),
        1,
      );
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(200, 1000),
        1,
      );
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(450, 1000),
        2,
      );
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(700, 1000),
        3,
      );
      expect(
        WorkoutConsistencyHeatmap.intensityLevelForVolume(900, 1000),
        4,
      );
    });

    testWidgets('renders all 365 day cells and notifies on tap', (tester) async {
      final anchor = DateTime(2026, 11, 17);
      final targetDay = DateTime(2026, 11, 10);
      DateTime? tappedDay;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkoutConsistencyHeatmap(
                anchorDate: anchor,
                activeDaysLastYear: 2,
                longestStreak: 2,
                selectedDay: null,
                volumeByDate: {
                  targetDay: 4200,
                  anchor: 2100,
                },
                workoutsByDate: {
                  targetDay: [
                    ProfileWorkoutSummary(
                      id: 1,
                      name: 'Push Day',
                      startTime: targetDay,
                      duration: const Duration(minutes: 50),
                      volume: 4200,
                      exercises: const ['Bench Press'],
                    ),
                  ],
                },
                onDaySelected: (day) => tappedDay = day,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifies 365 day window: anchor and 364 days earlier both exist in the matrix.
      final rangeStart = anchor.subtract(const Duration(days: 364));
      expect(
        find.byKey(
          Key('heatmap_cell_${rangeStart.year}_${rangeStart.month}_${rangeStart.day}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          Key('heatmap_cell_${anchor.year}_${anchor.month}_${anchor.day}'),
        ),
        findsOneWidget,
      );

      final targetCellFinder = find.byKey(
        Key('heatmap_cell_${targetDay.year}_${targetDay.month}_${targetDay.day}'),
      );
      expect(targetCellFinder, findsOneWidget);

      await tester.ensureVisible(targetCellFinder);
      await tester.tap(targetCellFinder);
      await tester.pump();

      expect(tappedDay, targetDay);
    });
  });
}
