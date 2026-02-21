
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/theme/app_theme.dart';
import '../../authentication/data/auth_repository.dart';
import '../data/history_repository.dart';
import '../domain/workout_stats.dart';

class HistoricalSummaryScreen extends ConsumerWidget {
  final DateTime date;

  const HistoricalSummaryScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider(date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE d, MMM').format(date).toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: statsAsync.when(
        data: (stats) {
          if (stats == null) {
            return const Center(child: Text("No se encontró registro para esta fecha."));
          }
          return _buildContent(context, ref, stats);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, WorkoutStats stats) {
    final user = ref.read(authRepositoryProvider).currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Atleta';
    final wasFasting = true; // Todo: Fetch if fasting from MetabolicCheckin historic data? 

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Success Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Main Title (Past Tense)
          Text(
            "¡Entrenaste Duro, $name!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Resumen de tu sesión histórica", // Context label
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // 3. Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem("Duración", "${stats.durationMinutes} min", Icons.timer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem("Calorías", "${stats.caloriesBurned} kcal", Icons.local_fire_department),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               Expanded(
                child: _buildStatItem("Volumen", "${stats.totalVolume.round()} kg", Icons.fitness_center),
              ),
              const SizedBox(width: 16),
               Expanded(
                child: _buildStatItem("Series", "${stats.totalSets}", Icons.layers),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 4. Insight (Past Tense)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.brandBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.brandBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppTheme.brandBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Insight de ese día",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.brandBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  wasFasting 
                      ? "Entrenar en ayunas aquel día potenció tu oxidación de grasas y sensibilidad a la insulina. ¡Excelente decisión!"
                      : "Tu carga de carbohidratos previa te dio la energía necesaria para maximizar el volumen.",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // 5. Navigation Button (Past Details)
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () {
                // Navigate to details (Assuming a route exists or just pop for now)
                // The requirement says "Ir al Seguimiento" -> Details of sets.
                // We might need to push a read-only view of the workout screen?
                // For now, let's assume we want to view the daily summary or just acknowledge.
                context.pop(); // Or navigate to specific detail view if implemented
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "Ir al Seguimiento",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
