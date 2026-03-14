import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/metabolic_checkin_provider.dart';
// For WorkoutRecommendation if needed for header?
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00FFB2).withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFB2).withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFB2).withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFB2).withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFF00FFB2), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "${widget.userDisplayName}, configuremos tu sesión...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
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
              inactiveColor: Colors.white12,
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
              inactiveColor: Colors.white12,
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
              inactiveColor: Colors.white12,
            )
          ),

          const SizedBox(height: 32),

          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF00FFB2), Color(0xFF009688)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFB2).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                ref.read(metabolicCheckinProvider.notifier).submitCheckin(
                  sleepHours: _sleepHours,
                  sorenessLevel: _sorenessLevel,
                  nutritionStatus: 'fed', 
                  energyLevel: _energyLevel,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "Sincronizar Metabolismo", 
                style: GoogleFonts.firaCode(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)
              ),
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
