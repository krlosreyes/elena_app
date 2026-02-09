import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BioGaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final String statusText;
  final Color statusColor;
  final String unit;
  final List<Color>? gradientColors;

  const BioGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.statusText,
    required this.statusColor,
    this.unit = '',
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculamos tamaños relativos al espacio disponible
          final double size = constraints.maxWidth;
          final double fontSizeValue = size * 0.22; // El número será el 22% del ancho
          final double fontSizeLabel = size * 0.08; // La etiqueta será el 8%

          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. El Arco (CustomPaint)
              CustomPaint(
                size: Size(size, size), // Ocupa todo el espacio
                painter: _GaugePainter(
                  value: value,
                  min: min,
                  max: max,
                  gradientColors: gradientColors ?? [Colors.green, Colors.yellow, Colors.orange, Colors.red],
                ), 
              ),

              // 2. El Contenido (Texto)
              Column(
                mainAxisAlignment: MainAxisAlignment.end, // Empujar hacia abajo
                children: [
                   // Espaciador superior para no chocar con el arco de arriba
                  const Spacer(flex: 4), 
                  
                  // El Valor Numérico
                  Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: GoogleFonts.outfit(
                      fontSize: fontSizeValue, // TAMAÑO DINÁMICO
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.0, // Reducir interlineado
                    ),
                  ),
                  
                  // El Estado (ej: Sobrepeso)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0), // Margen inferior
                    child: Text(
                      statusText,
                      style: GoogleFonts.outfit(
                        fontSize: fontSizeLabel, // TAMAÑO DINÁMICO
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // 3. Título (Arriba al centro)
              Positioned(
                top: 0,
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: size * 0.1, // Dinámico
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final List<Color> gradientColors;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = math.min(size.width / 2, size.height) - 10;
    
    // 1. Background Arc (Light Grey)
    final paintBg = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      paintBg,
    );

    // 2. Active Arc (Gradient)
    final clampedValue = value.clamp(min, max);
    final percentage = (clampedValue - min) / (max - min);
    final sweepAngle = percentage * math.pi;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paintGradient = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * 2,
        colors: gradientColors,
        tileMode: TileMode.clamp, // Ensure it doesn't repeat weirdly
      ).createShader(rect);

    // We need to draw the gradient arc only up to the sweep angle.
    // However, SweepGradient maps to the whole circle. To have the gradient stretch properly 
    // across 180 degrees (from pi to 2pi), we defined startAngle pi and endAngle 2pi.
    // The drawArc will clip this shader to just the part we draw.
    // IF we want the gradient to represent the full range (min to max) even if the arc is short:
    // The current shader setup does exactly that: Green is at min, Red is at max. 
    // The arc reveals the gradient up to the current value.

    canvas.drawArc(
      rect,
      math.pi,
      sweepAngle,
      false,
      paintGradient,
    );

    // 3. Floating Marker
    final markerAngle = math.pi + sweepAngle;
    final markerRadius = radius; // On the arc
    final markerCenter = Offset(
      center.dx + markerRadius * math.cos(markerAngle),
      center.dy + markerRadius * math.sin(markerAngle),
    );

    final paintMarker = Paint()
      ..color = Colors.black // Or dynamic color based on position? Black is clean/contrast.
      ..style = PaintingStyle.fill;
    
    final paintMarkerBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw Circle with border
    canvas.drawCircle(markerCenter, 6, paintMarker);
    canvas.drawCircle(markerCenter, 6, paintMarkerBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
