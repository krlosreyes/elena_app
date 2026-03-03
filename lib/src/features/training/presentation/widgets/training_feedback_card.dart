
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/metabolic_checkin_provider.dart';
import '../../application/training_engine_provider.dart';
import '../../../authentication/application/auth_controller.dart';
import 'metabolic_insight_banner.dart';
import '../../domain/entities/training_entities.dart';

class TrainingFeedbackCard extends ConsumerWidget {
  final WorkoutRecommendation recommendation;
  final bool isDeload;

  const TrainingFeedbackCard({
    super.key,
    required this.recommendation,
    required this.isDeload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Granular listen to execution state
    // We only want to rebuild this widget when isExecuting changes, 
    // but since we are wrapping the content, rebuilding the wrapper is fine.
    // The content itself (INSIGHT text) is relatively static per session.
    final isExecuting = ref.watch(
      trainingEngineProvider.select((state) => state.isExecuting),
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: isExecuting
          ? const SizedBox.shrink() // Collapse logic
          : _buildDashboardContent(context, ref),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref) {
    final user = ref.read(authControllerProvider.notifier).currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Atleta';
    
    // Logic extracted from old _buildFixedHeader
    String badgeEmoji = "💪";
    if (recommendation.notes.contains("Potencia")) badgeEmoji = "🏋️";
    if (recommendation.notes.contains("Definición")) badgeEmoji = "🔥";
    if (recommendation.notes.contains("Esencial")) badgeEmoji = "⚡";
    if (isDeload) badgeEmoji = "🧊";

    Color badgeColor = AppTheme.brandBlue;
    if (recommendation.notes.contains("Potencia")) badgeColor = Colors.orange;
    if (recommendation.notes.contains("Definición")) badgeColor = Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDeload ? Colors.teal.shade50 : AppTheme.surfaceColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          ConstrainedBox(
             constraints: const BoxConstraints(minHeight: 40),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           "ENTRENAMIENTO DE HOY",
                           style: GoogleFonts.outfit(
                             fontSize: 10, 
                             fontWeight: FontWeight.bold,
                             color: Colors.grey.shade500,
                             letterSpacing: 1.0,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "¡A darle, $name! • ${recommendation.durationMinutes} Min",
                           style: GoogleFonts.outfit(
                             fontSize: 16, 
                             fontWeight: FontWeight.w600,
                             color: Colors.black87,
                           ),
                         ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      "$badgeEmoji ${isDeload ? 'Descarga' : recommendation.notes}", 
                      style: GoogleFonts.outfit(
                        color: badgeColor, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
               ],
             ),
          ),
          
          const SizedBox(height: 16),

          // Insight Content
          Consumer(
            builder: (context, ref, _) {
               final checkin = ref.watch(metabolicCheckinProvider).asData?.value;
               
               if (isDeload) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science, color: Colors.teal.shade700),
                        const SizedBox(width: 12),
                         Expanded(
                           child: Text(
                            "Semana de Descarga: Volumen al 50%.",
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.teal.shade900),
                           ),
                         ),
                      ],
                    ),
                  );
               }
               
               if (checkin?.insightMessage != null) {
                  return SizedBox(
                    width: double.infinity,
                    child: Padding( 
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: MetabolicInsightBanner(
                         message: checkin!.insightMessage!, 
                         compact: false
                      ),
                    ),
                  );
               }
               
               return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
