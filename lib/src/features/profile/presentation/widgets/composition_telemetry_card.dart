import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/domain/models/user_model.dart';
import '../../../../domain/logic/elena_brain.dart';

class CompositionTelemetryCard extends StatelessWidget {
  final UserModel user;
  const CompositionTelemetryCard({super.key, required this.user});

  static const Color accentNeon = Color(0xFFFF9D00);
  static const Color whiteNeon = Colors.white;

  @override
  Widget build(BuildContext context) {
    // 1. Cálculo de IMC: weight / (height/100)^2
    final double imc =
        user.currentWeightKg / ((user.heightCm / 100) * (user.heightCm / 100));

    // 2. Cálculo automatizado de composición (US Navy + Elena Engine)
    final double? fat = ElenaBrain.calculateFatPercentage(
      heightCm: user.heightCm,
      waistCm: user.waistCircumferenceCm,
      neckCm: user.neckCircumferenceCm,
      hipCm: user.hipCircumferenceCm,
      isMale: user.gender == Gender.male,
    );

    final double? muscle = ElenaBrain.calculateMuscleMass(fatPercentage: fat);

    // Fallbacks si no hay perímetros suficientes
    final String fatText = fat != null ? '${fat.toStringAsFixed(1)}%' : '--';
    final String muscleText =
        muscle != null ? '${muscle.toStringAsFixed(1)}%' : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: accentNeon.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: accentNeon.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // MÉTRICA PRINCIPAL: PESO (PRIMARY)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                user.currentWeightKg.toStringAsFixed(1),
                style: GoogleFonts.jetBrainsMono(
                  color: accentNeon,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'KG',
                style: GoogleFonts.jetBrainsMono(
                  color: accentNeon.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              // Delta (Ejemplo: Δ -0.5kg como pide el prompt)
              Text(
                'Δ -0.5kg',
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF00FF00),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'COMPOSICIÓN CORPORAL // TELEMETRÍA',
            style: GoogleFonts.jetBrainsMono(
              color: accentNeon.withValues(alpha: 0.4),
              fontSize: 8,
              letterSpacing: 2,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white12, height: 1),
          ),

          // FILA DE TELEMETRÍA SECUNDARIA (SECONDARY)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSecondaryMetric('IMC', imc.toStringAsFixed(1)),
              _buildSecondaryMetric('% GRASA', fatText),
              _buildSecondaryMetric('% MÚSCULO', muscleText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            color: whiteNeon.withValues(alpha: 0.5),
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: whiteNeon,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
