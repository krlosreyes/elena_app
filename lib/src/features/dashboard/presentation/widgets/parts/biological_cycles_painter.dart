import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/core/theme/circadian_theme.dart';

class BiologicalCyclesPainter extends CustomPainter {
  final Color indicatorColor;
  final DateTime currentTime; 

  BiologicalCyclesPainter({
    required this.indicatorColor,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- MEDIDAS PROPORCIONALES ---
    final double radiusPhases = size.width * 0.38; // Coincide con Fasting/Eating Painters
    final double strokeWidthPhases = size.width * 0.05;
    final rectPhases = Rect.fromCircle(center: center, radius: radiusPhases);

    // SPEC-103.2: comunicación día/noche con símbolos sol/luna
    // sutiles en cima (00:00) y fondo (12:00) del reloj.
    // Reemplaza al SweepGradient anterior que enturbiaba el centro.
    _drawCelestialSymbols(canvas, center, size.width);

    // 1. Marcas horarias
    _drawHourMarkers(canvas, center, radiusPhases, size.width);

    // 2. Fases Biológicas Dinámicas
    for (var phase in CircadianRules.allPhases) {
      final bool isActive = CircadianRules.isPhaseActive(phase, currentTime);

      // SPEC-103.1: bajar saturación de la fase activa para que el
      // anillo exterior NO compita con el arco interno (verde ayuno /
      // naranja ventana). El usuario sigue identificando la fase
      // activa por el color + el texto "ACTIVO" en blanco, pero ya
      // no domina visualmente la card.
      final Color displayColor = isActive
          ? CircadianTheme.getColorForPhase(phase.label)
              .withValues(alpha: 0.45)
          : Colors.grey.withValues(alpha: 0.15);

      _drawPhase(
        canvas,
        rectPhases,
        phase.startHour,
        phase.endHour,
        displayColor,
        phase.label,
        strokeWidthPhases,
        isActive,
        size.width,
      );
    }
  }

  /// SPEC-103.4: símbolos día/noche AFUERA del reloj, al lado de los
  /// labels horarios.
  ///   Sol a la derecha del 06 (amanecer, ángulo 0 / este).
  ///   Luna a la izquierda del 18 (anochecer, ángulo π / oeste).
  ///
  /// El sol nace por el este (06:00) y se oculta por el oeste (18:00).
  /// Esa coherencia semántica es la clave del patrón.
  ///
  /// Radio 0.55 — al exterior del label numérico, que vive en ~0.51 y
  /// se extiende hasta ~0.525 por su ancho. El painter desborda
  /// ligeramente el SizedBox del CircadianClock pero el Stack padre
  /// no recorta (confirmado: el label "06" en sí ya desborda y se ve
  /// completo).
  void _drawCelestialSymbols(Canvas canvas, Offset center, double fullWidth) {
    final double iconRadius = fullWidth * 0.55;
    final double iconSize = fullWidth * 0.045;
    final Color tintColor = Colors.white.withValues(alpha: 0.40);

    // Sol en 06:00 → este → ángulo 0.
    const double sunAngle = 0;
    final sunPos = Offset(
      center.dx + iconRadius * math.cos(sunAngle),
      center.dy + iconRadius * math.sin(sunAngle),
    );
    _paintIcon(canvas, Icons.light_mode_outlined, sunPos, iconSize, tintColor);

    // Luna en 18:00 → oeste → ángulo π.
    const double moonAngle = math.pi;
    final moonPos = Offset(
      center.dx + iconRadius * math.cos(moonAngle),
      center.dy + iconRadius * math.sin(moonAngle),
    );
    _paintIcon(canvas, Icons.dark_mode_outlined, moonPos, iconSize, tintColor);
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset position,
    double size,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(position.dx - tp.width / 2, position.dy - tp.height / 2),
    );
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double radius, double fullWidth) {
    final paint = Paint()
      ..color = indicatorColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.2;

    // Distancias proporcionales
    final double markerStart = radius + (fullWidth * 0.05);
    final double markerEndBase = radius + (fullWidth * 0.08);
    final double textDistance = radius + (fullWidth * 0.13);

    for (int i = 0; i < 24; i++) {
      double angle = (i * (2 * math.pi / 24)) - (math.pi / 2);
      bool isMajor = i % 6 == 0;
      
      double end = isMajor ? markerEndBase + 5 : markerEndBase;
      
      canvas.drawLine(
        Offset(center.dx + markerStart * math.cos(angle), center.dy + markerStart * math.sin(angle)),
        Offset(center.dx + end * math.cos(angle), center.dy + end * math.sin(angle)),
        paint,
      );

      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: i.toString().padLeft(2, '0'),
            style: TextStyle(
              color: indicatorColor.withValues(alpha: 0.6),
              fontSize: fullWidth * 0.028, // Fuente proporcional
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        tp.paint(canvas, Offset(
          center.dx + textDistance * math.cos(angle) - tp.width / 2,
          center.dy + textDistance * math.sin(angle) - tp.height / 2,
        ));
      }
    }
  }

  void _drawPhase(Canvas canvas, Rect rect, double startH, double endH, Color color, String label, double strokeWidth, bool isActive, double fullWidth) {
    double startHour = startH;
    double endHour = endH;
    if (endHour <= startHour) endHour += 24;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = (startHour * (2 * math.pi / 24)) - (math.pi / 2);
    double sweepAngle = (endHour - startHour) * (2 * math.pi / 24);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // Texto de la fase adaptable
    final tp = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(), 
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.withValues(alpha: 0.4), 
          fontSize: fullWidth * 0.018, // Fuente proporcional
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    double midAngle = startAngle + (sweepAngle / 2);
    canvas.rotate(midAngle + math.pi / 2);
    double checkAngle = (midAngle + math.pi / 2) % (2 * math.pi);
    
    // El offset de los textos ahora depende del radio dinámico del rect
    double textRadiusOffset = rect.width / 2;

    if (checkAngle > math.pi / 2 && checkAngle < 3 * math.pi / 2) {
      canvas.rotate(math.pi);
      tp.paint(canvas, Offset(-tp.width / 2, textRadiusOffset - (tp.height / 2)));
    } else {
      tp.paint(canvas, Offset(-tp.width / 2, -textRadiusOffset - (tp.height / 2)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BiologicalCyclesPainter oldDelegate) {
    return oldDelegate.currentTime.minute != currentTime.minute || 
           oldDelegate.currentTime.hour != currentTime.hour;
  }
}