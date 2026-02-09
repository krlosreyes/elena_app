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
    // Usamos LayoutBuilder para saber exactamente cuánto espacio tenemos
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // Tamaños dinámicos basados en el ancho de la tarjeta
        final double titleSize = width * 0.09;
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
          padding: const EdgeInsets.all(8), // Reduced padding to 8
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Título Superior
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
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
                  alignment: Alignment.bottomCenter,
                  children: [
                    // El Arco (Ocupa todo el espacio disponible)
                    Positioned.fill(
                        child:  Align(
                            alignment: Alignment.center,
                             child: SizedBox(
                                width: width,
                                height: height * 0.60, // Reduced to 0.60 to prevent overflow
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
                      bottom: height * 0.02, // Lowered slightly
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$value$unit',
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
    final center = Offset(size.width / 2, size.height * 0.85); // Adjusted back to 0.85 as per original logic if height is constrained externally
    final radius = math.min(size.width / 2, size.height) * 0.85; // Fixed: utilize math.min
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
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      paintBackground,
    );

    // 2. Calcular porcentaje llenado
    final double percentage = (value - min) / (max - min);
    final double clampedPercentage = percentage.clamp(0.0, 1.0);
    final double sweepAngle = math.pi * clampedPercentage;

    // 3. Dibujar Arco Activo (Progreso)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      paintActive,
    );

    // 4. Dibujar Indicador (Bolita al final del progreso)
    final double indicatorAngle = math.pi + sweepAngle;
    final double indicatorX = center.dx + radius * math.cos(indicatorAngle);
    final double indicatorY = center.dy + radius * math.sin(indicatorAngle);

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
