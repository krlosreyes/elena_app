import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FastingMotivationCard extends StatelessWidget {
  final Duration elapsed;

  const FastingMotivationCard({super.key, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    String message = '';

    if (hours < 4) {
      message = 'Tu cuerpo está digiriendo y bajando la insulina.';
    } else if (hours < 12) {
      message = 'Niveles de glucosa estables. Descanso digestivo.';
    } else if (hours < 14) {
      message = '¡Quema de grasa activada! Estás usando reservas.';
    } else if (hours < 16) {
      message = 'Cetosis ligera. Energía mental y enfoque.';
    } else {
      message = 'Autofagia. Reciclaje celular profundo.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Llevas ${hours}h',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
