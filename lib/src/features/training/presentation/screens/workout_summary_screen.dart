import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/workout_log.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../authentication/application/auth_controller.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  static const String routeName = 'workout_summary';
  
  final WorkoutLog log;

  const WorkoutSummaryScreen({super.key, required this.log});

  @override
  ConsumerState<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Play confetti automatically on entry
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    // final duration = widget.log.durationMinutes ?? 45; // unused
    // int totalSets = 0; // unused
    double totalVolume = 0;
    int totalReps = 0;

    for (var ex in widget.log.completedExercises) {
      final sets = ex['sets'] as List<dynamic>;
      for (var set in sets) {
        if (set['isDone'] == true) {
          // totalSets++;
          final weight = set['weight'] as num?;
          final reps = set['reps'] as num?;
          if (reps != null) {
              totalReps += reps.toInt();
              if (weight != null) {
                totalVolume += (weight * reps);
              }
          }
        }
      }
    }
    
    // Estimate Stimulus Time (TUT) ~ 4s per rep
    final int stimulusSeconds = totalReps * 4;
    final String stimulusTime = stimulusSeconds > 60 
        ? "${(stimulusSeconds / 60).toStringAsFixed(1)} min" 
        : "$stimulusSeconds sec";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Trophy Icon with Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                         Container(
                           width: 100,
                           height: 100,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.amber.shade100.withValues(alpha: 0.5),
                             boxShadow: [
                               BoxShadow(
                                 color: Colors.amber.withValues(alpha: 0.2),
                                 blurRadius: 20,
                                 spreadRadius: 5,
                               )
                             ]
                           ),
                         ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 64,
                          color: Colors.amber,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Personalized Header
                  Consumer(
                    builder: (context, ref, _) {
                      final user = ref.read(authControllerProvider.notifier).currentUser;
                      final name = user?.displayName?.split(' ').first ?? 'Atleta';
                      
                      return Column(
                        children: [
                          Text(
                            "¡Misión Cumplida, $name!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Has vencido a tu versión de ayer.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  
                  const SizedBox(height: 32),

                  // Insight Card (Conditional)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                         Row(
                           children: [
                             Icon(widget.log.isFasted ? Icons.bolt : Icons.restaurant, color: AppTheme.brandBlue),
                             const SizedBox(width: 8),
                             Text(
                               widget.log.isFasted ? "ENTRENAMIENTO EN AYUNAS" : "ENTRENAMIENTO ALIMENTADO", 
                               style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.brandBlue, fontSize: 12)
                             ),
                           ],
                         ),
                         const SizedBox(height: 12),
                         Consumer(
                           builder: (context, ref, _) {
                              final user = ref.read(authControllerProvider.notifier).currentUser;
                              final name = user?.displayName?.split(' ').first ?? 'Atleta';
                              
                              return Text(
                                widget.log.isFasted
                                    ? "$name, entrenar en ayunas hoy ha potenciado tu flexibilidad metabólica. Tu síntesis proteica se disparará cuando rompas el ayuno. ¡Mantente hidratado hasta tu próxima comida!"
                                    : "$name, gran uso de tu energía hoy. Tus niveles de insulina actuales facilitarán el transporte de aminoácidos a tus músculos tras este esfuerzo. ¡Asegura tu comida post-entreno!",
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: Colors.blueGrey.shade800,
                                  height: 1.4,
                                ),
                              );
                           }
                         ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                         child: _MetricCard(
                           label: "Volumen Total",
                           value: totalVolume > 999 
                               ? "${(totalVolume/1000).toStringAsFixed(1)}Ton" 
                               : "${totalVolume.toInt()}kg",
                           icon: Icons.monitor_weight_outlined,
                           color: Colors.purple,
                         ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                         child: _MetricCard(
                           label: "Tiempo Estímulo",
                           value: stimulusTime,
                           icon: Icons.timer,
                           color: Colors.orange,
                         ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Next Steps (CTA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration( 
                       color: Colors.grey.shade50,
                       borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text("PRÓXIMA MISIÓN 👇", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.5)),
                         const SizedBox(height: 8),
                         Text(
                           "Mañana toca Cardio.",
                           style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "Hacerlo dentro de tu ventana de ayuno será el toque final para limpiar tu sistema y acelerar la recuperación. ¿Aceptas el reto?",
                           style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                         ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/dashboard');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Volver al Inicio",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Confetti Widget Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // down
              maxBlastForce: 20, // increased for more impact
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
