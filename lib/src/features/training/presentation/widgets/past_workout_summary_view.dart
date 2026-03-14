import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/workout_log.dart';
import '../../../../config/theme/app_theme.dart';

class PastWorkoutSummaryView extends StatelessWidget {
  final WorkoutLog log;

  const PastWorkoutSummaryView({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    // Calculate simple stats
    // Duration
    final duration = log.durationMinutes ?? 45; // Mock fallback
    
    // Volume (if strength)
    // Calories (mock estimation based on duration)
    // Strength ~ 6 kcal/min, Cardio ~ 8 kcal/min
    // We don't have type in Log easily yet without checking exercises, let's assume average 7
    final calories = duration * 7;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 24),
          Text(
            "Entrenamiento Completado",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ya registraste actividad para este día.",
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: "$duration min",
                label: "Duración",
                icon: Icons.timer,
              ),
              _StatItem(
                value: "$calories",
                label: "Kcal",
                icon: Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
