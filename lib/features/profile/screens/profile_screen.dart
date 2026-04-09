// lib/features/profile/screens/profile_screen.dart

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
  // Cambio: antes el error sólo se mostraba en un SnackBar (que desaparece),
  // dejando el body congelado con "Could not load user profile." sin forma de
  // reintentar. Ahora _errorMessage se usa también para mostrar un retry en el body.
  String? _errorMessage;

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
            ],
          ),
        ],
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
