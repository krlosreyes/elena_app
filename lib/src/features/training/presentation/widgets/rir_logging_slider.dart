import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';

class RirLoggingSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RirLoggingSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "¿CUÁNTAS REPETICIONES MÁS SENTÍAS QUE PODÍAS HACER?",
          style: GoogleFonts.firaCode(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("0 (FALLO)", style: _labelStyle),
                  Text("1", style: _labelStyle),
                  Text("2", style: _labelStyle),
                  Text("3", style: _labelStyle),
                  Text("4+", style: _labelStyle),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF00FFB2),
                  inactiveTrackColor: Colors.white.withOpacity(0.1),
                  thumbColor: const Color(0xFF00FFB2),
                  overlayColor: const Color(0xFF00FFB2).withOpacity(0.1),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 4,
                  divisions: 4,
                  onChanged: (val) => onChanged(val.toInt()),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFB2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRirDescription(value).toUpperCase(),
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00FFB2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _labelStyle => GoogleFonts.firaCode(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      );

  String _getRirDescription(int val) {
    switch (val) {
      case 0: return "Fallo Muscular (0 RIR)";
      case 1: return "1 Rep en Reserva";
      case 2: return "2 Reps en Reserva";
      case 3: return "3 Reps en Reserva";
      case 4: return "4+ Reps (Muy fácil)";
      default: return "";
    }
  }
}
