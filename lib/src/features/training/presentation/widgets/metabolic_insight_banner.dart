import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetabolicInsightBanner extends StatelessWidget {
  final String message;
  final bool compact; // Added compact mode

  const MetabolicInsightBanner({
    required this.message, 
    this.compact = false,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
        return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBBDEFB)),
        ),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Icon(Icons.psychology, color: Color(0xFF1565C0), size: 16),
            const SizedBox(width: 8),
                Flexible(
                child: Text(
                message,
                style: GoogleFonts.outfit(
                    color: const Color(0xFF0D47A1),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                ),
                ),
            ],
        ),
        );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16), // Generous padding
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.psychology, color: Color(0xFF1565C0), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.left, // Explicit left align
              style: GoogleFonts.outfit(
                color: const Color(0xFF0D47A1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.4, // Better breathability
              ),
            ),
          ),
        ],
      ),
    );
  }
}
