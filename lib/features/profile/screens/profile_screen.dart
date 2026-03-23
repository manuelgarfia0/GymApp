// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../../../core/di/core_dependencies.dart';
import '../../../core/errors/failures.dart';
import '../../workouts/domain/entities/workout.dart';
import '../../workouts/domain/use_cases/get_workout_history.dart';
import '../../workouts/workout_dependencies.dart';
import '../domain/entities/user_profile.dart';
import '../domain/use_cases/get_current_user_profile.dart';
import '../profile_dependencies.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final GetCurrentUserProfile _getCurrentUserProfile;
  late final GetWorkoutHistory _getWorkoutHistory;

  UserProfile? _user;
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserProfile = ProfileDependencies.getCurrentUserProfileUseCase;
    _getWorkoutHistory = WorkoutDependencies.getWorkoutHistoryUseCase;
    _loadDashboardData();
  }

  /// Carga el perfil y el historial de entrenamientos.
  ///
  /// Obtiene el userId desde [SessionService] a través del JWT,
  /// sin depender de [SharedPreferences] como fuente secundaria.
  Future<void> _loadDashboardData() async {
    final userId = await CoreDependencies.sessionService.getUserId();

    if (userId == null || userId <= 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final user = await _getCurrentUserProfile();
      final workouts = await _getWorkoutHistory(userId);

      if (mounted) {
        setState(() {
          _user = user;
          _workouts = workouts;
          _isLoading = false;
        });
      }
    } on AuthenticationFailure catch (e) {
      _handleError(e.message);
    } on NetworkFailure catch (e) {
      _handleError(e.message, isRetryable: true);
    } on ValidationFailure catch (e) {
      _handleError(e.message, color: Colors.amber);
    } catch (_) {
      _handleError(
        'Failed to load profile data. Please try again.',
        isRetryable: true,
      );
    }
  }

  void _handleError(
    String message, {
    bool isRetryable = false,
    Color color = Colors.red,
  }) {
    if (!mounted) return;
    setState(() {
      _user = null;
      _workouts = [];
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        action: isRetryable
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadDashboardData();
                },
              )
            : null,
      ),
    );
  }

  String _calculateTotalTime() {
    final total = _workouts.fold<Duration>(
      Duration.zero,
      (sum, w) =>
          w.endTime != null ? sum + w.endTime!.difference(w.startTime) : sum,
    );
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'Could not load user profile.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _user!.isPremium
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _user!.isPremium ? Colors.amber : Colors.grey,
              ),
            ),
            child: Text(
              _user!.isPremium ? 'PRO Member' : 'Free Plan',
              style: TextStyle(
                color: _user!.isPremium ? Colors.amber : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
              _buildStatCard(
                'Total Workouts',
                _workouts.length.toString(),
                Icons.fitness_center,
                Colors.blueAccent,
              ),
              _buildStatCard(
                'Time Trained',
                _calculateTotalTime(),
                Icons.timer,
                Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
