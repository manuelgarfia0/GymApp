// lib/features/profile/screens/profile_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/di/core_dependencies.dart';
import '../../../core/errors/failures.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/weight_converter.dart';
import '../../../core/widgets/anatomical_muscle_heatmap.dart';
import '../../../core/widgets/slow_loading_indicator.dart';
import '../domain/entities/user_profile.dart';
import '../domain/use_cases/get_current_user_profile.dart';
import '../domain/use_cases/get_user_stats.dart';
import '../presentation/screens/edit_profile_screen.dart';
import '../presentation/widgets/workout_consistency_heatmap.dart';
import '../profile_dependencies.dart';
import '../../settings/presentation/screens/settings_screen.dart';
import '../../workouts/presentation/screens/workout_detail_screen.dart';

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

  List<Widget> _buildProfileIdentityHeader(
    BuildContext context,
    AppStrings strings,
  ) {
    final user = _user!;
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);
    final fullName = [user.firstName, user.lastName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .map((part) => part!.trim())
        .join(' ');
    final dob = user.dateOfBirth;
    final dobLabel = dob != null && user.showDateOfBirth
        ? '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}'
        : null;
    final langCode = (user.languagePreference ?? 'es').toLowerCase();
    final langLabel = langCode == 'en' ? 'English' : 'Español';

    return [
      if (fullName.isNotEmpty) ...[
        Text(
          fullName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.blueAccent,
          ),
        ),
      ] else
        Text(
          user.username,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      const SizedBox(height: 6),
      Text(
        user.email,
        style: TextStyle(fontSize: 15, color: secondaryText),
      ),
      const SizedBox(height: 14),
      _PremiumBadge(isPremium: user.isPremium),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (dobLabel != null)
            _ProfileMetaChip(
              icon: Icons.cake_outlined,
              label: dobLabel,
            ),
          _ProfileMetaChip(
            icon: Icons.language_rounded,
            label: langLabel,
          ),
          _ProfileMetaChip(
            icon: user.publicProfile
                ? Icons.public_rounded
                : Icons.lock_outline_rounded,
            label: user.publicProfile
                ? strings.publicProfileLabel
                : strings.privateProfileLabel,
          ),
          if (!user.showGlobalStats)
            _ProfileMetaChip(
              icon: Icons.visibility_off_outlined,
              label: strings.hiddenStatsLabel,
            ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            key: const Key('profile_edit_button'),
            onPressed: _openEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: Text(strings.editProfile),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueAccent,
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.65)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
          OutlinedButton.icon(
            key: const Key('profile_settings_button'),
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, size: 17),
            label: Text(strings.settings),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary(context),
              side: BorderSide(color: AppTheme.borderColor(context)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _openEditProfile() async {
    final current = _user;
    if (current == null) return;

    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: current,
          updateUserProfileUseCase:
              ProfileDependencies.updateUserProfileUseCase,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil actualizado correctamente',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unit = AppSettingsScope.of(context).weightUnit;
    final strings = AppStrings.of(context);
    final primaryText = AppTheme.textPrimary(context);
    final secondaryText = AppTheme.textSecondary(context);

    if (_isLoading) {
      return const SlowLoadingIndicator();
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
                style: TextStyle(color: secondaryText, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
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
      );
    }

    return RefreshIndicator(
      color: Colors.blueAccent,
      backgroundColor: AppTheme.cardBg(context),
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            ..._buildProfileIdentityHeader(context, strings),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
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
                  value: WeightConverter.formatCompactVolume(
                    _stats.totalVolume,
                    unit,
                  ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mapa muscular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnatomicalMuscleHeatmap(heatmapsByRange: _stats.muscleHeatmaps),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Calendario de actividad (365 días)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            WorkoutConsistencyHeatmap(
              volumeByDate: _stats.volumeHistory,
              workoutsByDate: _stats.workoutsByDate,
              selectedDay: _selectedDay,
              activeDaysLastYear: _stats.activeDaysLastYear,
              longestStreak: _stats.longestStreak,
              onDaySelected: _selectDay,
            ),
            if (_selectedDay != null && _selectedDayWorkouts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Workouts',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedDayWorkouts.map(
                (w) => _buildWorkoutSummaryCard(w, unit),
              ),
            ],
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Volume History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildVolumeChart(unit),
          ],
        ),
      ),
    );
  }

  void _selectDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    setState(() {
      _selectedDay = dayKey;
      _selectedDayWorkouts = _stats.workoutsByDate[dayKey] ?? [];
    });
  }

  String _formatDurationHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildWorkoutSummaryCard(
    ProfileWorkoutSummary summary,
    WeightUnit unit,
  ) {
    final start =
        '${summary.startTime.hour.toString().padLeft(2, '0')}:${summary.startTime.minute.toString().padLeft(2, '0')}';
    final durationStr = _formatDurationHms(summary.duration);
    final prCount = summary.personalRecords.length;
    final volumeText = WeightConverter.formatVolume(summary.volume, unit);

    return Card(
      color: AppTheme.cardBg(context),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: summary.workout == null
            ? null
            : () async {
                final deleted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutDetailScreen(
                      workout: summary.workout!,
                      personalRecords: summary.personalRecords,
                    ),
                  ),
                );
                if (deleted == true && mounted) {
                  _load();
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  if (prCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        '🏆 $prCount PR',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (summary.workout != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary(context),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$start · $durationStr · ${summary.setCount} sets · $volumeText',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (summary.exercises.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${summary.exercises.take(3).join(", ")}${summary.exercises.length > 3 ? ' (+${summary.exercises.length - 3})' : ''}',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeChart(WeightUnit unit) {
    if (_stats.volumeHistory.isEmpty) {
      return Center(
        child: Text(
          "No volume data yet.",
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
      );
    }

    final sortedEntries = _stats.volumeHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = sortedEntries.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        WeightConverter.fromKg(e.value.value, unit),
      );
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: AppTheme.isDark(context)
            ? null
            : Border.all(color: AppTheme.borderColor(context)),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = sortedEntries[spot.x.toInt()].key;
                  final vol = spot.y;
                  final dateStr =
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                  return LineTooltipItem(
                    '$dateStr\n${vol.toStringAsFixed(1)} ${unit.label}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedEntries.length) {
                    final date = sortedEntries[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 22,
                interval: (sortedEntries.length / 5)
                    .clamp(1.0, double.infinity)
                    .toDouble(),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
      color: AppTheme.cardBg(context),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
