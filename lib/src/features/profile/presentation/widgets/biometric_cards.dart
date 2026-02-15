import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BiometricDetailCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String? subValue;
  final String statusText;
  final Color statusColor;

  const BiometricDetailCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    this.subValue,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              if (subValue != null) ...[
                const Spacer(),
                Text(
                  subValue!,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class BiometricBarCard extends StatelessWidget {
  final String title;
  final String valueLabel;
  final double progress; // 0.0 to 1.0
  final String statusText;
  final Color statusColor;
  final Color barColor;
  final String? notes;

  const BiometricBarCard({
    super.key,
    required this.title,
    required this.valueLabel,
    required this.progress,
    required this.statusText,
    required this.statusColor,
    required this.barColor,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                valueLabel,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          if (notes != null) ...[
            const SizedBox(height: 8),
            Text(
              notes!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class IdealWeightProgressCard extends StatelessWidget {
  final double currentWeight;
  final double idealWeight;
  final double startWeight; // To calculate progress percentage if needed, or just use current/ideal relation

  const IdealWeightProgressCard({
    super.key,
    required this.currentWeight,
    required this.idealWeight,
    this.startWeight = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Progress calculation logic
    // We want to show how close current is to ideal.
    // However, recomposition is complex. A simple bar:
    // Left: Current (if losing) or Ideal (if gaining)?
    // Let's visualize it as a target achievement.
    
    // Validamos delta para evitar divisiones por cero
    double progress = 0.0;
    
    // Asumimos que el objetivo es llegar al peso ideal. 
    // Si startWeight se provee, podemos mostrar progreso desde el inicio.
    // Si no, mostramos qué tan cerca estamos del ideal relativo a una desviación estándar o simplemente un valor visual.
    
    // Enfoque simplificado solicitado: "Barra de progreso con marcadores"
    // Vamos a usar una lógica de: Cuánto falta para el ideal.
    
    final diff = (currentWeight - idealWeight).abs();
    
    // Si la diferencia es < 1kg, está completado.
    bool isCompleted = diff < 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PROGRESO PESO IDEAL",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
               Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? "¡Logrado!" : "En proceso",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Custom Progress Bar with Markers
          Stack(
            children: [
              Container(
                height: 24, // Thick bar
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                   // Calculate simplified progress for visualization
                   // Assuming a visual range of +/- 20kg from ideal for context? 
                   // Or simpler: Just a filled bar representing current status vs target?
                   
                   // Let's do a simple interpolation: 
                   // If losing weight: Start > Current > Ideal
                   // If gaining: Start < Current < Ideal
                   
                   // Fallback for visual stability
                   double percentage = 0.5; 
                   
                   if (startWeight > 0) {
                     final totalDist = (startWeight - idealWeight).abs();
                     final covered = (startWeight - currentWeight).abs();
                     if (totalDist > 0) percentage = covered / totalDist;
                     if (percentage > 1.0) percentage = 1.0;
                   }

                   return Container(
                    height: 24,
                    width: constraints.maxWidth * percentage.clamp(0.05, 1.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.cyan]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }
              ),
              // Text Overlay
              const Center(
                 child: SizedBox(
                   height: 24,
                 ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Actual",
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    "${currentWeight.toStringAsFixed(1)} kg",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Objetivo (Masa Magra)",
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    "${idealWeight.toStringAsFixed(1)} kg",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                  ),
                ],
              ),
            ],
          ),
           const SizedBox(height: 8),
           Text(
             "Basado en tu masa magra actual y % grasa objetivo.",
             style: GoogleFonts.outfit(
               fontSize: 12,
               color: Colors.grey[500],
               fontStyle: FontStyle.italic,
             ),
           ),
        ],
      ),
    );
  }
}
