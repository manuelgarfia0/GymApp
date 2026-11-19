import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../auth/auth_dependencies.dart';
import '../../workouts/presentation/screens/routines_screen.dart';
import '../../workouts/presentation/screens/workout_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../workouts/workout_dependencies.dart';
import '../../workouts/domain/entities/personal_record.dart';
import '../../workouts/domain/entities/workout.dart';
import '../../workouts/domain/use_cases/evaluate_personal_records.dart';
import '../../../core/di/core_dependencies.dart';
import '../../../core/errors/failures.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_converter.dart';
import '../../../core/widgets/slow_loading_indicator.dart';
import '../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _historyVersion = 0;
  int _profileVersion = 0;

  @override
  void initState() {
    super.initState();
    WorkoutDependencies.workoutSavedNotifier.addListener(_onWorkoutSaved);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          CoreDependencies.permissionsService.requestRequiredPermissions(),
        );
      }
    });
  }

  @override
  void dispose() {
    WorkoutDependencies.workoutSavedNotifier.removeListener(_onWorkoutSaved);
    super.dispose();
  }

  void _onWorkoutSaved() {
    if (mounted) {
      setState(() {
        _currentIndex = 0;
        _historyVersion++;
        _profileVersion++;
      });
    }
  }

  Future<void> _logout() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardBg(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          strings.logoutTitle,
          style: TextStyle(
            color: AppTheme.textPrimary(dialogContext),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          strings.logoutMessage,
          style: TextStyle(
            color: AppTheme.textSecondary(dialogContext),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              strings.cancel,
              style: TextStyle(color: AppTheme.textSecondary(dialogContext)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              strings.logOut,
              style: const TextStyle(
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
      CoreDependencies.permissionsService.resetSession();
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

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) {
      setState(() => _profileVersion++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final bg = AppTheme.scaffoldBg(context);
    final textPrimary = AppTheme.textPrimary(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Progressive',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('home_settings_button'),
            tooltip: strings.settingsTooltip,
            icon: Icon(Icons.settings_rounded, color: textPrimary),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: strings.logoutTooltip,
            icon: Icon(Icons.logout_rounded, color: textPrimary),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _WorkoutHistoryTab(key: ValueKey('history_$_historyVersion')),
          const RoutinesScreen(),
          ProfileScreen(key: ValueKey('profile_$_profileVersion')),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            if (i == 0) _historyVersion++;
            if (i == 2) _profileVersion++;
            _currentIndex = i;
          });
        },
      ),
    );
  }
}

// ── Workout history tab ──────────────────────────────────────────────────────

class _WorkoutHistoryData {
  final List<Workout> workouts;
  final Map<int, List<PersonalRecordAchievement>> prsByWorkout;

  const _WorkoutHistoryData({
    required this.workouts,
    required this.prsByWorkout,
  });
}

class _WorkoutHistoryTab extends StatefulWidget {
  const _WorkoutHistoryTab({super.key});

  @override
  State<_WorkoutHistoryTab> createState() => _WorkoutHistoryTabState();
}

class _WorkoutHistoryTabState extends State<_WorkoutHistoryTab> {
  late Future<_WorkoutHistoryData> _futureHistory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _futureHistory = _fetchHistory();
  }

  Future<_WorkoutHistoryData> _fetchHistory() async {
    final userId = await CoreDependencies.sessionService.getUserId();
    if (userId == null || userId <= 0) {
      return const _WorkoutHistoryData(workouts: [], prsByWorkout: {});
    }
    final workouts = await WorkoutDependencies.getWorkoutHistoryUseCase(userId);
    final prsByWorkout = WorkoutDependencies.evaluatePersonalRecordsUseCase
        .evaluateHistoryByWorkout(workouts);
    return _WorkoutHistoryData(
      workouts: workouts,
      prsByWorkout: prsByWorkout,
    );
  }

  Future<void> _confirmAndDeleteWorkout(Workout workout) async {
    final workoutId = workout.id;
    if (workoutId == null || workoutId <= 0) return;

    final confirmed = await showDeleteWorkoutConfirmDialog(
      context,
      workout.name,
    );
    if (!confirmed || !mounted) return;

    try {
      await WorkoutDependencies.deleteWorkoutUseCase(workoutId);
      WorkoutDependencies.notifyWorkoutSaved();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Entrenamiento eliminado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
      }
    } on Failure catch (e) {
      if (mounted) _showDeleteError(e.message);
    } catch (e) {
      final cleanMsg = e
          .toString()
          .replaceFirst(
            RegExp(r'^(Exception:\s*|ServerException:\s*|Failure:\s*)'),
            '',
          )
          .trim();
      if (mounted) {
        _showDeleteError(
          cleanMsg.isNotEmpty
              ? cleanMsg
              : 'No se pudo eliminar el entrenamiento',
        );
      }
    }
  }

  void _showDeleteError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: AppTheme.cardBg(context),
      onRefresh: () async => setState(() => _load()),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text(
                strings.workoutHistoryTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          FutureBuilder<_WorkoutHistoryData>(
            future: _futureHistory,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SlowLoadingIndicator(),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                final message = error is Failure
                    ? error.message
                    : 'No se pudo cargar el historial. Inténtalo de nuevo.';
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
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
                            'Could not load workout history',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _load()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(strings.retry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final historyData = snapshot.data ??
                  const _WorkoutHistoryData(workouts: [], prsByWorkout: {});
              final workouts = historyData.workouts;

              if (workouts.isEmpty) {
                return const SliverFillRemaining(child: _EmptyHistory());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final workout = workouts[index];
                      final prs = historyData.prsByWorkout[
                              EvaluatePersonalRecords.workoutKey(workout)] ??
                          const <PersonalRecordAchievement>[];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WorkoutCard(
                          workout: workout,
                          personalRecordsCount: prs.length,
                          onDelete: workout.id != null && workout.id! > 0
                              ? () => _confirmAndDeleteWorkout(workout)
                              : null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkoutDetailScreen(
                                workout: workout,
                                personalRecords: prs,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
  final int personalRecordsCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _WorkoutCard({
    required this.workout,
    this.personalRecordsCount = 0,
    required this.onTap,
    this.onDelete,
  });

  double get _totalVolume => workout.sets
      .where((s) => !s.isWarmup)
      .fold(0, (sum, s) => sum + (s.weight * s.reps));

  int get _exerciseCount =>
      workout.sets.map((s) => s.exerciseId).toSet().length;

  // Cambio: Ahora muestra HH:MM:SS
  String get _duration {
    if (workout.endTime == null) return 'In progress';
    final d = workout.endTime!.difference(workout.startTime);
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final volumeLabel = WeightConverter.formatVolume(_totalVolume, unit);
    final cardBg = AppTheme.cardBg(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: AppTheme.isDark(context)
              ? null
              : Border.all(color: AppTheme.borderColor(context)),
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _date,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (personalRecordsCount > 0) ...[
                    _Pill(
                      label: '🏆 $personalRecordsCount PR',
                      bgColor: Colors.amber.withValues(alpha: 0.16),
                      textColor: Colors.amber,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      key: Key('workout_card_menu_${workout.id}'),
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                      color: AppTheme.elevatedBg(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      onSelected: (value) {
                        if (value == 'delete') onDelete!();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Eliminar entrenamiento',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: textSecondary,
                    ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(color: AppTheme.borderColor(context), height: 1),
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
                    value: volumeLabel,
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
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted(context), fontSize: 10),
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
      color: AppTheme.borderColor(context),
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
            bgColor: AppTheme.elevatedBg(context),
            textColor: AppTheme.textSecondary(context),
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
            Text(
              'No workouts yet',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed workouts will appear here.\nHead to Train to get started.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 14,
              ),
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = [
      _NavItem(icon: Icons.history_rounded, label: strings.navHistory),
      _NavItem(icon: Icons.bolt_rounded, label: strings.navWorkouts),
      _NavItem(icon: Icons.person_rounded, label: strings.navProfile),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navBarBg(context),
        border: Border(
          top: BorderSide(color: AppTheme.borderColor(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              final inactive = AppTheme.textMuted(context);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].icon,
                        color: selected ? Colors.blueAccent : inactive,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected ? Colors.blueAccent : inactive,
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
