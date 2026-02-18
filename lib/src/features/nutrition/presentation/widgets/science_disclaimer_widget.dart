import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScienceDisclaimerWidget extends StatelessWidget {
  const ScienceDisclaimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.science_outlined, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Calculado usando la fórmula Katch-McArdle basada en tu Masa Libre de Grasa.",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
