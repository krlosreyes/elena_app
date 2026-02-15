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
          "¿Cuántas repeticiones más sentías que podías hacer?",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("0 (Fallo)", style: _labelStyle),
                  Text("1", style: _labelStyle),
                  Text("2", style: _labelStyle),
                  Text("3", style: _labelStyle),
                  Text("4+", style: _labelStyle),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.brandTeal,
                  inactiveTrackColor: AppTheme.brandTeal.withOpacity(0.2),
                  thumbColor: AppTheme.brandTeal,
                  overlayColor: AppTheme.brandTeal.withOpacity(0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: 0,
                  max: 4,
                  divisions: 4,
                  onChanged: (val) => onChanged(val.toInt()),
                ),
              ),
              Center(
                child: Text(
                  _getRirDescription(value),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _labelStyle => GoogleFonts.outfit(
        fontSize: 12,
        color: Colors.grey[600],
      );

  String _getRirDescription(int val) {
    switch (val) {
      case 0: return "Fallo Muscular (0 RIR)";
      case 1: return "1 Repetición en Reserva";
      case 2: return "2 Repeticiones en Reserva";
      case 3: return "3 Repeticiones en Reserva";
      case 4: return "4+ Repeticiones en Reserva (Muy fácil)";
      default: return "";
    }
  }
}
