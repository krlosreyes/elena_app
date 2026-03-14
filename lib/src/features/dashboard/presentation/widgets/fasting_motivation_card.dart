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
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Color(0xFF00FFB2), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Llevas ',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '${hours}h',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00FFB2),
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
