import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/nutrition_plan.dart';

class VisualPlateWidget extends StatelessWidget {
  final VisualPlate plate;

  const VisualPlateWidget({super.key, required this.plate});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomPaint(
            painter: _PlatePainter(
              vegPercent: plate.vegetablesPercent,
              proteinPercent: plate.proteinPercent,
              carbsPercent: plate.carbsPercent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    "El Plato Meta",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandDark,
                    ),
                  ),
                  Text(
                    "50/25/25",
                     style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatePainter extends CustomPainter {
  final double vegPercent;
  final double proteinPercent;
  final double carbsPercent;

  _PlatePainter({
    required this.vegPercent,
    required this.proteinPercent,
    required this.carbsPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paintVeg = Paint()..color = const Color(0xFF81C784); // Green 300
    final paintProtein = Paint()..color = const Color(0xFFE57373); // Red 300
    final paintCarbs = Paint()..color = const Color(0xFFFFD54F); // Amber 300

    // Veggies (Usually 50% - Half circle)
    // Start from -90 deg (top)
    double startAngle = -1.5708; // -90 degrees in radians
    double sweepVeg = 2 * 3.14159 * vegPercent;
    canvas.drawArc(rect, startAngle, sweepVeg, true, paintVeg);

    // Protein
    double sweepProtein = 2 * 3.14159 * proteinPercent;
    canvas.drawArc(rect, startAngle + sweepVeg, sweepProtein, true, paintProtein);

    // Carbs
    double sweepCarbs = 2 * 3.14159 * carbsPercent;
    canvas.drawArc(rect, startAngle + sweepVeg + sweepProtein, sweepCarbs, true, paintCarbs);
    
    // Labels (Simplified drawing for now, could be improved with TextPainters)
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
