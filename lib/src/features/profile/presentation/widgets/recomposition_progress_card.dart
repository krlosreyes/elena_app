import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Import UserModel

class RecompositionProgressCard extends StatelessWidget {
  final double currentWeight;
  final double currentFatPercentage;
  final double? targetFatPercentage; // From UserModel
  final double? targetLBM; // From UserModel

  const RecompositionProgressCard({
    super.key,
    required this.currentWeight,
    required this.currentFatPercentage,
    this.targetFatPercentage,
    this.targetLBM,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Current LBM
    final double currentLBM = currentWeight * (1 - (currentFatPercentage / 100));

    // 2. Determine Targets (with defaults)
    final double targetFat = targetFatPercentage ?? 15.0; // Default 15%
    // If targetLBM is not set, use currentLBM (maintain muscle goal)
    final double targetLBMVal = targetLBM ?? currentLBM; 

    // 3. Calculate Progress Values
    // Specific logic requested:
    // Fat Progress: visualize current % against a theoretical max of 40% (to show "filling up" the bad side? No, usually progress means towards goal).
    // The request says: "value = (currentFatPercentage / 40.0).clamp(0.0, 1.0)".
    // This implies the bar represents the MAGNITUDE of fat, not progress towards reduction.
    // Higher bar = More fat (bad).
    final double fatProgress = (currentFatPercentage / 40.0).clamp(0.0, 1.0);

    // LBM Progress: "value = (currentLBM / targetLBM).clamp(0.0, 1.0)".
    // Higher bar = More muscle (good).
    final double lbmProgress = (targetLBMVal > 0) 
        ? (currentLBM / targetLBMVal).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "RECOMPOSICIÓN CORPORAL",
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Body Fat Section
          _buildMetricRow(
            label: "Grasa Corporal",
            currentVal: "${currentFatPercentage.toStringAsFixed(1)}%",
            targetVal: "${targetFat.toStringAsFixed(1)}%",
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fatProgress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Lean Body Mass Section
          _buildMetricRow(
            label: "Masa Magra",
            currentVal: "${currentLBM.toStringAsFixed(1)} kg",
            targetVal: "${targetLBMVal.toStringAsFixed(1)} kg",
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: lbmProgress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({required String label, required String currentVal, required String targetVal}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
            children: [
              const TextSpan(text: "Actual: "),
              TextSpan(
                text: currentVal, 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const TextSpan(text: "  |  Meta: "),
              TextSpan(text: targetVal),
            ],
          ),
        ),
      ],
    );
  }
}
