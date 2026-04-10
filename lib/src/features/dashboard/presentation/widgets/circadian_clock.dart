import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../../domain/fasting_status.dart';

class CircadianClock extends StatelessWidget {
  final UserModel user;
  final FastingState fastingState;
  final double score;
  final String zone;

  const CircadianClock({
    super.key,
    required this.user,
    required this.fastingState,
    required this.score,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final colorDeTexto = Theme.of(context).colorScheme.onBackground;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 440, // Aumentamos un poco para dar aire a las etiquetas externas
          width: 440,
          child: CustomPaint(
            painter: CircadianClockPainter(
              fastingProgress: (fastingState.duration.inSeconds / (24 * 3600)).clamp(0.0, 1.0),
              phaseColor: _getPhaseColor(fastingState.phase),
              indicatorColor: colorDeTexto,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "IMR SCORE",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorDeTexto.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "${score.toInt()}",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 85, 
                height: 1.1,
                color: colorDeTexto, 
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppColors.metabolicGreen, size: 18),
                Text(
                  zone.toUpperCase(), 
                  style: const TextStyle(
                    color: AppColors.metabolicGreen, 
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _getPhaseColor(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.postAbsorption: return Colors.lightBlueAccent;
      case FastingPhase.transition: return Colors.orangeAccent;
      case FastingPhase.fatBurning: return AppColors.metabolicGreen;
      case FastingPhase.autophagy: return const Color(0xFF6366F1);
      default: return AppColors.metabolicGreen;
    }
  }
}

class CircadianClockPainter extends CustomPainter {
  final double fastingProgress;
  final Color phaseColor;
  final Color indicatorColor;

  CircadianClockPainter({
    required this.fastingProgress, 
    required this.phaseColor,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 65; 
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // 1. Dibujar marcas y números (00, 06, 12, 18)
    _drawHourMarkers(canvas, center, radius);

    // 2. Fases Biológicas
    _drawPhase(canvas, rect, 22, 30, 6, 0, const Color(0xFF1E293B), "SUEÑO");
    _drawPhase(canvas, rect, 6, 0, 9, 0, const Color(0xFF475569), "ALERTA");
    _drawPhase(canvas, rect, 9, 0, 13, 0, const Color(0xFFFB923C), "COGNITIVO");
    _drawPhase(canvas, rect, 13, 0, 15, 0, const Color(0xFF60A5FA), "RECESO");
    _drawPhase(canvas, rect, 15, 0, 20, 0, const Color(0xFFF87171), "MOTOR / FUERZA");
    _drawPhase(canvas, rect, 20, 0, 22, 30, const Color(0xFFFACC15), "CREATIVIDAD");

    // 3. Anillo de Ayuno
    final innerRadius = radius - 45;
    canvas.drawCircle(center, innerRadius, Paint()
      ..color = indicatorColor.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10);

    if (fastingProgress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: innerRadius), 
          -math.pi / 2, math.pi * 2 * fastingProgress, false, Paint()
        ..color = phaseColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10);
    }

    _drawLiveIndicator(canvas, center, radius);
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = indicatorColor.withOpacity(0.4)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 24; i++) {
      double angle = (i * (2 * math.pi / 24)) - (math.pi / 2);
      bool isMajor = i % 6 == 0;
      
      // Ajuste de distancias para que no choquen con las fases
      double start = radius + 30;
      double end = radius + (isMajor ? 45 : 35);
      
      canvas.drawLine(
        Offset(center.dx + start * math.cos(angle), center.dy + start * math.sin(angle)),
        Offset(center.dx + end * math.cos(angle), center.dy + end * math.sin(angle)),
        paint,
      );

      // DIBUJO DE LOS NÚMEROS (00, 06, 12, 18)
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: i.toString().padLeft(2, '0'), 
            style: TextStyle(
              color: indicatorColor.withOpacity(0.8), 
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        // Posicionamos el texto un poco más afuera de las líneas
        tp.paint(canvas, Offset(
          center.dx + (end + 15) * math.cos(angle) - tp.width / 2,
          center.dy + (end + 15) * math.sin(angle) - tp.height / 2,
        ));
      }
    }
  }

  void _drawLiveIndicator(Canvas canvas, Offset center, double radius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (2 * math.pi / 24)) - (math.pi / 2);
    double orbitRadius = radius - 32; 
    final pos = Offset(center.dx + orbitRadius * math.cos(angle), center.dy + orbitRadius * math.sin(angle));

    canvas.drawCircle(pos, 8, Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawCircle(pos, 6, Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    canvas.drawCircle(pos, 4, Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill);
  }

  void _drawPhase(Canvas canvas, Rect rect, int h1, int m1, int h2, int m2, Color color, String label) {
    double startHour = h1 + (m1 / 60.0);
    double endHour = h2 + (m2 / 60.0);
    if (endHour <= startHour) endHour += 24;

    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 45;
    double startAngle = (startHour * (2 * math.pi / 24)) - (math.pi / 2);
    double sweepAngle = (endHour - startHour) * (2 * math.pi / 24);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    final tp = TextPainter(
      text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    double midAngle = startAngle + (sweepAngle / 2);
    canvas.rotate(midAngle + math.pi / 2);

    double checkAngle = (midAngle + math.pi / 2) % (2 * math.pi);
    if (checkAngle > math.pi / 2 && checkAngle < 3 * math.pi / 2) {
      canvas.rotate(math.pi);
      tp.paint(canvas, Offset(-tp.width / 2, (rect.width / 2) - (tp.height / 2)));
    } else {
      tp.paint(canvas, Offset(-tp.width / 2, -(rect.width / 2) - (tp.height / 2)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}