import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/training_engine_provider.dart';
import '../../domain/entities/training_entities.dart';
import '../widgets/rir_logging_slider.dart';

class DailyWorkoutScreen extends ConsumerWidget {
  const DailyWorkoutScreen({super.key});

  static const String routeName = 'daily_workout';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationAsync = ref.watch(trainingEngineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrenamiento de Hoy"),
      ),
      body: recommendationAsync.when(
        data: (recommendation) => _buildContent(context, recommendation),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WorkoutRecommendation recommendation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationCard(context, recommendation),
          const SizedBox(height: 24),
          Text(
            "Registro de Esfuerzo",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Demo of the slider (in a real app, this would be part of a logging form)
          Consumer(
            builder: (context, ref, _) {
              // Local state for demo purposes using a StateProvider if needed, 
              // or just a simple StatefulBuilder would suffice for standalone widget demo.
              // But prompts asked for a Stateless ConsumerWidget screen. 
              // Let's us a simple StatefulWidget wrapper for the slider demo or just render it static.
              // To make it interactive without full implementation, I'll use a StatefulBuilder.
              return StatefulBuilder(
                builder: (context, setState) {
                  int rirValue = 2; // Default
                  return RirLoggingSlider(
                    value: rirValue,
                    onChanged: (val) {
                       setState(() => rirValue = val);
                    },
                  );
                }
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, WorkoutRecommendation recommendation) {
    Color cardColor;
    IconData icon;

    switch (recommendation.type) {
      case 'Strength':
        cardColor = AppTheme.brandBlue;
        icon = Icons.fitness_center;
        break;
      case 'Cardio':
        cardColor = Colors.orange;
        icon = Icons.directions_run;
        break;
      case 'ActiveRecovery':
        cardColor = AppTheme.brandTeal;
        icon = Icons.spa;
        break;
      case 'Deload':
        cardColor = Colors.purple;
        icon = Icons.battery_charging_full;
        break;
      default:
        cardColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                recommendation.type.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            recommendation.targetMuscle != null 
                ? "Objetivo: ${recommendation.targetMuscle!.name.toUpperCase()}" 
                : "Objetivo: GENERAL",
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${recommendation.durationMinutes} Minutos  •  ${recommendation.intensity}",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              recommendation.notes,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
