import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetabolicInsightBanner extends StatelessWidget {
  final String message;

  const MetabolicInsightBanner({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container( // Changed from card to container or just use as is
       // Actually user requested "Area fija en la tarjeta de entrenamiento"
       // This widget will be injected into that card.
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light Blue surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row( // Using Row for icon + text
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: Color(0xFF1565C0), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0D47A1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
