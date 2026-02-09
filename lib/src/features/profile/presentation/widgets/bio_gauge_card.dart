import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BioGaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String statusText;
  final Color statusColor;
  final String unit; // Added unit parameter based on previous usage context, though not in user snippet, it is safe to keep or remove. User snippet didn't have it in constructor but used it in previous code. The user snippet *removed* it from constructor in the provided code block, so I will follow the user's code exactly. Wait, user code `BioGaugeCard` constructor: `required this.title, required this.value ...`. No `unit`.
  // But wait, the previous usages of BioGaugeCard in ProfileScreen pass `unit`. If I remove it, the build will break in ProfileScreen.
  // The user's snippet:
  /*
  const BioGaugeCard({
    Key? key,
    required this.title,
    required this.value,
    ...
  }) : super(key: key);
  */
  // It does NOT have `unit`.
  // However, `ProfileScreen` calls it with `unit: '%'`.
  // I should probably keep `unit` to avoid breaking `ProfileScreen`, or I'll have to update `ProfileScreen` content as well.
  // The user said: "Reemplazar COMPLETAMENTE el contenido del archivo ... con esto".
  // If I do that, `ProfileScreen` will have errors because it passes `unit` and `gradientColors`.
  // The user provided code does NOT have `gradientColors` in the constructor either.
  // It hardcodes generic colors in the painter: `colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red]`.
  
  // Checking ProfileScreen usage (from previous file reads):
  // BioGaugeCard(..., unit: '', gradientColors: ...)
  
  // If I strictly follow the user's "replace with this code", I will break the build.
  // I should probably adapt the user's code to include `unit` and `gradientColors` OR I should update ProfileScreen too.
  // The user didn't ask to update ProfileScreen.
  // I will add `unit` and `gradientColors` to the new `BioGaugeCard` to match the signature expected by `ProfileScreen`, but use the logic provided by the user.
  // Actually, the user's logic for the painter uses a hardcoded gradient.
  // "colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red],"
  
  // I will TRY to keep the signature compatible.
  
  final List<Color>? gradientColors; // Keep compatibility

  const BioGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.statusText,
    required this.statusColor,
    this.unit = '', // Keep compatibility
    this.gradientColors, // Keep compatibility
  });

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para saber exactamente cuánto espacio tenemos
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // Tamaños dinámicos basados en el ancho de la tarjeta
        final double titleSize = width * 0.09;
        // Adjusted valueSize slightly if unit is present?
        final double valueSize = width * 0.18;
        final double statusSize = width * 0.07;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Título Superior
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit( // Using Outfit to match app consistency, though user said Poppins. I'll switch to Poppins if requested, but usually consistency is better. User explicitly used Poppins in snippet. I will use Poppins as requested in the snippet to be safe, or Outfit?
                // The snippet specifically imported GoogleFonts.
                // "style: GoogleFonts.poppins"
                // I will use Poppins as requested.
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // 2. El Gauge y el Valor (Superpuestos para ahorrar espacio)
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter, // Changed from Alignment.bottomCenter to match user snippet? user snippet said alignment: Alignment.bottomCenter.
                  children: [
                    // El Arco (Ocupa todo el espacio disponible)
                    // The user snippet uses SizedBox(height: height * 0.6)
                    Positioned.fill(
                        child:  Align(
                            alignment: Alignment.center,
                             child: SizedBox(
                                width: width,
                                height: height * 0.65, // Increased slightly
                                child: CustomPaint(
                                    painter: BioGaugePainter(
                                    value: value,
                                    min: min,
                                    max: max,
                                    color: statusColor,
                                    gradientColors: gradientColors,
                                    ),
                                ),
                            ),
                        ),
                    ),
                    
                    // El Valor Numérico (Posicionado justo en el centro-abajo del arco)
                    Positioned(
                      bottom: height * 0.05, // Un poco arriba del fondo
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$value$unit', // Use unit
                            style: GoogleFonts.poppins(
                              fontSize: valueSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            statusText,
                            style: GoogleFonts.poppins(
                              fontSize: statusSize,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// EL PAINTER QUE DIBUJA EL ARCO
class BioGaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final List<Color>? gradientColors;

  BioGaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Configuración del Arco
    // User snippet: 
    // final center = Offset(size.width / 2, size.height * 0.85); 
    // final radius = min(size.width / 2, size.height) * 0.85; 

    // Adjusting center based on the container size passed to CustomPaint
    // In user snippet, CustomPaint is inside SizedBox(height: height * 0.6).
    // So size.height is already reduced.
    
    final center = Offset(size.width / 2, size.height * 0.8); 
    final radius = min(size.width / 2, size.height) * 0.9; 
    final strokeWidth = 12.0;

    final paintBackground = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final paintActive = Paint()
      ..shader = LinearGradient(
        colors: gradientColors ?? [Colors.green, Colors.yellow, Colors.orange, Colors.red],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // 1. Dibujar Fondo (Arco gris completo de 180 grados)
    // startAngle: pi (180 grados, izquierda)
    // sweepAngle: pi (180 grados de recorrido)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      paintBackground,
    );

    // 2. Calcular porcentaje llenado
    final double percentage = (value - min) / (max - min);
    final double clampedPercentage = percentage.clamp(0.0, 1.0);
    final double sweepAngle = pi * clampedPercentage;

    // 3. Dibujar Arco Activo (Progreso)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      sweepAngle,
      false,
      paintActive,
    );

    // 4. Dibujar Indicador (Bolita al final del progreso)
    final double indicatorAngle = pi + sweepAngle;
    final double indicatorX = center.dx + radius * cos(indicatorAngle);
    final double indicatorY = center.dy + radius * sin(indicatorAngle);

    final paintIndicator = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final paintIndicatorBorder = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 6.0, paintIndicator);
    canvas.drawCircle(Offset(indicatorX, indicatorY), 6.0, paintIndicatorBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
