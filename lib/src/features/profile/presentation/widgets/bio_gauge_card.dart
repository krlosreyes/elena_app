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
  final String unit;
  final List<Color>? gradientColors;

  const BioGaugeCard({
    Key? key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.statusText,
    required this.statusColor,
    this.unit = '',
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Forzamos que la tarjeta sea CUADRADA. Esto evita que se vea "aplastada".
    return AspectRatio(
      aspectRatio: 1.0, 
      child: Container(
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
        // 2. Padding interno relativo
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // "size" es el ancho disponible dentro de la tarjeta
            final double size = constraints.maxWidth;
            
            // 3. MATEMÁTICA PURA (Nada de pixeles fijos)
            final double titleSize = size * 0.09;  // Título = 9% del ancho
            final double valueSize = size * 0.20;  // Valor = 20% del ancho
            final double statusSize = size * 0.08; // Estado = 8% del ancho
            final double gaugeHeight = size * 0.65; // El arco ocupa 65% de altura

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TÍTULO
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // ZONA DEL GRÁFICO
                SizedBox(
                  height: gaugeHeight, 
                  width: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // CAPA A: El Arco
                      CustomPaint(
                        size: Size(size, gaugeHeight),
                        painter: BioGaugePainter(
                          value: value,
                          min: min,
                          max: max,
                          color: statusColor,
                          gradientColors: gradientColors,
                        ),
                      ),

                      // CAPA B: El Texto (Centrado y desplazado hacia abajo)
                      Positioned(
                        top: gaugeHeight * 0.45, // Justo debajo del centro del arco
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
                            Text(
                              statusText,
                              style: GoogleFonts.poppins(
                                fontSize: statusSize,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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
    // Geometría adaptativa
    final center = Offset(size.width / 2, size.height * 0.6); // Centro del arco
    final radius = size.width / 2.2; // Radio un poco menor al ancho total
    final strokeWidth = size.width * 0.08; // Grosor relativo al tamaño

    final paintBg = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Arco de fondo (180 grados)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, pi, false, paintBg
    );

    // Gradiente activo
    final paintActive = Paint()
      ..shader = LinearGradient(colors: gradientColors ?? [Colors.green, Colors.yellow, Colors.orange, Colors.red])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Calcular ángulo
    final double percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final double sweepAngle = pi * percentage;

    // Dibujar progreso
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, sweepAngle, false, paintActive
    );

    // Indicador (Bolita)
    final double indicatorAngle = pi + sweepAngle;
    final double dx = center.dx + radius * cos(indicatorAngle);
    final double dy = center.dy + radius * sin(indicatorAngle);

    canvas.drawCircle(Offset(dx, dy), strokeWidth * 0.6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dx, dy), strokeWidth * 0.6, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
