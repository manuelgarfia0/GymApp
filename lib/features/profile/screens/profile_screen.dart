// lib/features/profile/screens/profile_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import '../../../core/di/core_dependencies.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities/user_profile.dart';
import '../domain/use_cases/get_current_user_profile.dart';
import '../domain/use_cases/get_user_stats.dart';
import '../profile_dependencies.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final GetCurrentUserProfile _getCurrentUserProfile;
  late final UserStatsRepository _statsRepository;

  UserProfile? _user;
  UserStats _stats = UserStats.empty;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ProfileWorkoutSummary> _selectedDayWorkouts = [];

  @override
  void initState() {
    super.initState();
    // Cambio: ya no se importa WorkoutDependencies aquí.
    // Las estadísticas se obtienen a través de ProfileDependencies.statsRepository,
    // que internamente usa WorkoutRepository sin exponer la dependencia al feature.
    _getCurrentUserProfile = ProfileDependencies.getCurrentUserProfileUseCase;
    _statsRepository = ProfileDependencies.statsRepository;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = await CoreDependencies.sessionService.getUserId();
    if (userId == null || userId <= 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _getCurrentUserProfile(),
        _statsRepository.getStats(userId),
      ]);

      if (mounted) {
        setState(() {
          _user = results[0] as UserProfile?;
          _stats = results[1] as UserStats;
          _isLoading = false;
        });
      }
    } on AuthenticationFailure catch (e) {
      _setError(e.message);
    } on NetworkFailure catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Failed to load profile. Please try again.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    // Cambio: el error ahora se muestra inline con un botón Retry visible,
    // en lugar de sólo en un SnackBar que desaparece.
    if (_errorMessage != null || _user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Could not load profile.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _user!.username,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _user!.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _PremiumBadge(isPremium: _user!.isPremium),
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                title: 'Total Workouts',
                value: _stats.totalWorkouts.toString(),
                icon: Icons.fitness_center,
                color: Colors.blueAccent,
              ),
              _StatCard(
                title: 'Time Trained',
                value: _stats.totalTime,
                icon: Icons.timer,
                color: Colors.greenAccent,
              ),
              _StatCard(
                title: 'Total Volume',
                value: '${(_stats.totalVolume / 1000).toStringAsFixed(1)}k',
                icon: Icons.monitor_weight,
                color: Colors.orangeAccent,
              ),
              _StatCard(
                title: 'Current Streak',
                value: '${_stats.currentStreak} days',
                icon: Icons.local_fire_department,
                color: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Training Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendar(),
          if (_selectedDay != null && _selectedDayWorkouts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Workouts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._selectedDayWorkouts.map((w) => _buildWorkoutSummaryCard(w)),
          ],
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Volume History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildVolumeChart(),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummaryCard(ProfileWorkoutSummary workout) {
    final start = '${workout.startTime.hour.toString().padLeft(2, '0')}:${workout.startTime.minute.toString().padLeft(2, '0')}';
    final durH = workout.duration.inHours;
    final durM = workout.duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final durationStr = durH > 0 ? '${durH}h ${durM}m' : '${durM}m';

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Time: $start • Duration: $durationStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text('Exercises: ${workout.exercises.take(3).join(", ")}${workout.exercises.length > 3 ? '...' : ''}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text('Volume: ${workout.volume.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            final dayKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            _selectedDayWorkouts = _stats.workoutsByDate[dayKey] ?? [];
          });
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.blueAccent),
          weekendStyle: TextStyle(color: Colors.blueAccent),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white),
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final isWorkoutDay = _stats.workoutDates.any((d) =>
                d.year == day.year && d.month == day.month && d.day == day.day);
            if (isWorkoutDay) {
              return Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildVolumeChart() {
    if (_stats.volumeHistory.isEmpty) {
      return const Center(child: Text("No volume data yet.", style: TextStyle(color: Colors.grey)));
    }

    final sortedEntries = _stats.volumeHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    final spots = sortedEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = sortedEntries[spot.x.toInt()].key;
                  final vol = spot.y;
                  final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  return LineTooltipItem(
                    '$dateStr\n${vol.toStringAsFixed(1)} kg',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final date = sortedEntries[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${date.day}/${date.month}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 22,
                interval: (sortedEntries.length / 5).clamp(1.0, double.infinity).toDouble(),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orangeAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orangeAccent.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  final bool isPremium;
  const _PremiumBadge({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPremium ? Colors.amber : Colors.grey),
      ),
      child: Text(
        isPremium ? 'PRO Member' : 'Free Plan',
        style: TextStyle(
          color: isPremium ? Colors.amber : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
