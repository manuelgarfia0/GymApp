import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/auth_dependencies.dart';
import '../../workouts/presentation/screens/routines_screen.dart';
import '../../workouts/presentation/screens/workout_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workouts/workout_dependencies.dart';
import '../../workouts/domain/entities/workout.dart';
import '../../../core/di/core_dependencies.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AuthDependencies.repository.logout();
    } catch (_) {
    } finally {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LoginScreen(loginUseCase: AuthDependencies.loginUseCase),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Progressive',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _WorkoutHistoryTab(),
          RoutinesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Workout history tab ──────────────────────────────────────────────────────

class _WorkoutHistoryTab extends StatefulWidget {
  const _WorkoutHistoryTab();

  @override
  State<_WorkoutHistoryTab> createState() => _WorkoutHistoryTabState();
}

class _WorkoutHistoryTabState extends State<_WorkoutHistoryTab> {
  late Future<List<Workout>> _futureWorkouts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _futureWorkouts = _fetchWorkouts();
  }

  Future<List<Workout>> _fetchWorkouts() async {
    final userId = await CoreDependencies.sessionService.getUserId();
    if (userId == null || userId <= 0) return [];
    return WorkoutDependencies.getWorkoutHistoryUseCase(userId);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF1E1E1E),
      onRefresh: () async => setState(() => _load()),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                'Workout History',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          FutureBuilder<List<Workout>>(
            future: _futureWorkouts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                );
              }

              final workouts = snapshot.data ?? [];

              if (workouts.isEmpty) {
                return const SliverFillRemaining(child: _EmptyHistory());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _WorkoutCard(
                        workout: workouts[index],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutDetailScreen(workout: workouts[index]),
                          ),
                        ),
                      ),
                    ),
                    childCount: workouts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Workout card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const _WorkoutCard({required this.workout, required this.onTap});

  double get _totalVolume =>
      workout.sets.fold(0, (sum, s) => sum + (s.weight * s.reps));

  int get _exerciseCount =>
      workout.sets.map((s) => s.exerciseId).toSet().length;

  // Cambio: antes mostraba "1h 23m". Ahora muestra "1:23" (h:mm) cuando
  // hay horas, o "45 min" cuando es menos de una hora. Sin abreviaturas.
  String get _duration {
    if (workout.endTime == null) return 'In progress';
    final d = workout.endTime!.difference(workout.startTime);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}';
    return '${d.inMinutes} min';
  }

  String get _date {
    final now = DateTime.now();
    final d = workout.startTime;
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today · ${DateFormat('HH:mm').format(d)}';
    }
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) {
      return 'Yesterday · ${DateFormat('HH:mm').format(d)}';
    }
    return DateFormat('MMM d, yyyy · HH:mm').format(d);
  }

  // Cambio: antes abreviaba con "k" a partir de 1000 kg ("1.2k kg").
  // Ahora muestra siempre el número completo ("1234 kg") para que el
  // usuario vea el volumen real sin ambigüedad.
  String get _volumeLabel {
    final v = _totalVolume;
    return '${v.toStringAsFixed(0)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF555555),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              const SizedBox(height: 14),

              Row(
                children: [
                  _StatItem(
                    icon: Icons.timer_outlined,
                    value: _duration,
                    label: 'Duration',
                  ),
                  _VerticalDivider(),
                  _StatItem(
                    icon: Icons.fitness_center_rounded,
                    value: '$_exerciseCount',
                    label: _exerciseCount == 1 ? 'Exercise' : 'Exercises',
                  ),
                  _VerticalDivider(),
                  _StatItem(
                    icon: Icons.repeat_rounded,
                    value: '${workout.sets.length}',
                    label: 'Sets',
                  ),
                  _VerticalDivider(),
                  _StatItem(
                    icon: Icons.monitor_weight_outlined,
                    value: _volumeLabel,
                    label: 'Volume',
                  ),
                ],
              ),

              if (workout.sets.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ExercisePills(workout: workout),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ───────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ExercisePills extends StatelessWidget {
  final Workout workout;

  const _ExercisePills({required this.workout});

  @override
  Widget build(BuildContext context) {
    final seen = <int>{};
    final names = workout.sets
        .where((s) => seen.add(s.exerciseId))
        .map((s) => s.exerciseName ?? 'Exercise')
        .toList();

    final visible = names.take(3).toList();
    final extra = names.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visible.map(
          (name) => _Pill(
            label: name,
            bgColor: const Color(0xFF2A2A2A),
            textColor: const Color(0xFFAAAAAA),
          ),
        ),
        if (extra > 0)
          _Pill(
            label: '+$extra more',
            bgColor: Colors.blueAccent.withValues(alpha: 0.12),
            textColor: Colors.blueAccent,
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No workouts yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed workouts will appear here.\nHead to Train to get started.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.history_rounded, label: 'History'),
    _NavItem(icon: Icons.bolt_rounded, label: 'Train'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[index].icon,
                        color: selected
                            ? Colors.blueAccent
                            : const Color(0xFF555555),
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[index].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.blueAccent
                              : const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
