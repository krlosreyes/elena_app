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
    // Formatting safety
    final String formattedValue = value.toStringAsFixed(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Enforce square aspect ratio or fit within available space
        final size = constraints.maxWidth;
        
        // Adaptive Metrics
        final double titleSize = size * 0.08; 
        final double valueSize = size * 0.18; 
        final double statusSize = size * 0.07;
        final double gaugeHeight = size * 0.55; // Controlled height for gauge

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
          padding: EdgeInsets.symmetric(
            horizontal: size * 0.05,
            vertical: size * 0.05,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. TITLE
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

              // 2. GAUGE + VALUE STACK
              SizedBox(
                height: gaugeHeight,
                width: size,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // A. The Arc Painter
                    Positioned.fill(
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
                    
                    // B. The Value Text (Centered in the "arch" space)
                    Positioned(
                      bottom: gaugeHeight * 0.1, // Lift slightly from bottom
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$formattedValue$unit', 
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
                              height: 1.0,
                            ),
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
    // Robust geometry: 
    // Arc is a semi-circle (180 deg) at the top part.
    // We base calculations on the width to ensure it fits.
    
    final double strokeWidth = size.width * 0.08;
    final double w = size.width;
    // final double h = size.height; // Not strictly needed if we base on width
    
    // Center point for the arc. 
    // We want the arc to arch UPWARDS. 
    // Center should be roughly at bottom-center of the available draw area.
    final center = Offset(w / 2, size.height * 0.9); 
    
    // Radius: fit within width with padding
    final radius = (w / 2) - strokeWidth;

    final paintBg = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Draw Background Arc (180 degrees, from PI to 2PI)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, // Start at 9 o'clock
      pi, // Sweep 180 deg to 3 o'clock
      false, 
      paintBg
    );

    // Active Gradient
    final paintActive = Paint()
      ..shader = LinearGradient(
        colors: gradientColors ?? [Colors.green, Colors.yellow, Colors.orange, Colors.red]
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    // Calculate progress
    final double safeValue = value.clamp(min, max);
    final double range = max - min;
    // Avoid division by zero
    final double percentage = range == 0 ? 0 : ((safeValue - min) / range);
    
    final double sweepAngle = pi * percentage;

    // Draw Active Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, 
      sweepAngle, 
      false, 
      paintActive
    );

    // Indicator Dot (Knob)
    final double indicatorAngle = pi + sweepAngle;
    final double dx = center.dx + radius * cos(indicatorAngle);
    final double dy = center.dy + radius * sin(indicatorAngle);

    // White border for contrast
    canvas.drawCircle(Offset(dx, dy), strokeWidth * 0.6, Paint()..color = Colors.white);
    // Colored center
    canvas.drawCircle(Offset(dx, dy), strokeWidth * 0.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
