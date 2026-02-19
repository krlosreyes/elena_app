import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/metabolic_checkin_provider.dart';
import '../../domain/entities/metabolic_state.dart';
import '../../domain/entities/training_entities.dart'; // For WorkoutRecommendation if needed for header?
// Actually the header needs WorkoutRecommendation for the "FullBody" badge.
// We can pass it in or fetch it.
// The badge "notes" comes from the DailyWorkout plan.

class DailyDiagnosticCard extends ConsumerStatefulWidget {
  final String userDisplayName;

  const DailyDiagnosticCard({
    super.key,
    required this.userDisplayName,
  });

  @override
  ConsumerState<DailyDiagnosticCard> createState() => _DailyDiagnosticCardState();
}

class _DailyDiagnosticCardState extends ConsumerState<DailyDiagnosticCard> {
  // Form State
  double _sleepHours = 7.0;
  int _sorenessLevel = 2;
  double _energyLevel = 7.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted margin
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandBlue.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandBlue.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.brandTeal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.monitor_heart_outlined, color: AppTheme.brandTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "${widget.userDisplayName}, configuremos tu sesión...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Question 1: Sleep
          _buildSliderQuestion(
            "1. ¿Horas de sueño?", 
            "$_sleepHours h", 
            Colors.blueAccent,
            Slider(
              value: _sleepHours,
              min: 3,
              max: 12,
              divisions: 18,
              onChanged: (v) => setState(() => _sleepHours = v),
              activeColor: Colors.blueAccent,
            )
          ),

          // Question 2: Soreness
          _buildSliderQuestion(
            "2. ¿Dolor muscular? (1-5)", 
            "$_sorenessLevel", 
            Colors.redAccent,
            Slider(
              value: _sorenessLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => setState(() => _sorenessLevel = v.toInt()),
              activeColor: Colors.redAccent,
            )
          ),
          
          // Question 3: Energy
          _buildSliderQuestion(
            "3. ¿Nivel de energía? (1-10)", 
            "${_energyLevel.toInt()}", 
            Colors.amber,
            Slider(
              value: _energyLevel,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _energyLevel = v),
              activeColor: Colors.amber,
            )
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              ref.read(metabolicCheckinProvider.notifier).submitCheckin(
                sleepHours: _sleepHours,
                sorenessLevel: _sorenessLevel,
                nutritionStatus: 'fed', 
                energyLevel: _energyLevel,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              "Sincronizar Metabolismo", 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderQuestion(String title, String valueLabel, Color color, Widget slider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
             Text(valueLabel, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SizedBox(
          height: 36,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
             child: slider,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
