import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/metabolic_hub_provider.dart';
import '../../../core/science/metabolic_engine.dart';
import '../../domain/models/metabolic_milestone.dart';

/// ✅ CIRCADIAN WHEEL WIDGET (Unified)
///
/// Corazón visual de ElenaApp. Representa el ciclo metabólico de 24h,
/// integrando ayuno, nutrición, biometría (glucosa/cetonas) y los hitos
/// fisiológicos. Reemplaza las versiones anteriores fragmentadas.
class CircadianWheelWidget extends StatefulWidget {
  final MetabolicContext context;
  final String durationStr;
  final String statusLabel; // E.g. "AYUNO", "DIGESTIÓN"
  final String subLabel; // E.g. "FASE: AUTOFAGIA"
  final bool isRestingWarning;
  final double? imrScore;
  final Color? zoneColor; // Reemplaza fastingColor hardcodeado si se pasa

  const CircadianWheelWidget({
    super.key,
    required this.context,
    required this.durationStr,
    required this.statusLabel,
    required this.subLabel,
    this.isRestingWarning = false,
    this.imrScore,
    this.zoneColor,
  });

  @override
  State<CircadianWheelWidget> createState() => _CircadianWheelWidgetState();
}

class _CircadianWheelWidgetState extends State<CircadianWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Controlar el inicio/parada del parpadeo basado en el estado
    if (widget.context.isWindowClosing && widget.context.isFeeding) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0; // Reset a opacidad completa
      }
    }

    final bool isFeeding = widget.context.isFeeding;
    final Color mainColor = isFeeding
        ? const Color(0xFFFFD600)
        : (widget.zoneColor ?? const Color(0xFF00E5FF));

    // 🏷️ Tag Dinámico para Cierre de Ventana
    final String displayStatusLabel =
        widget.context.isWindowClosing && isFeeding
        ? "CIERRE DE VENTANA"
        : widget.statusLabel;

    final List<MetabolicMilestone> allMilestones = [
      if (isFeeding) ...widget.context.mealMilestones,
      if (!isFeeding) ...widget.context.physiologicalMilestones,
    ];

    // Identificar el hito activo (objetivo actual)
    final double currentProgress =
        (widget.context.fastingStatus?.elapsed.inMinutes ?? 0) / 60.0;
    MetabolicMilestone? activeMilestone;

    final sortedMilestones = List<MetabolicMilestone>.from(allMilestones)
      ..sort((a, b) => a.hour.compareTo(b.hour));

    for (var m in sortedMilestones) {
      if (m.hour > currentProgress) {
        activeMilestone = m;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        // Usamos un factor conservador para el radio del track principal
        // para dejar espacio a los hitos y etiquetas que orbitan fuera
        final double radius = availableWidth * 0.35;
        final double wheelSize = math.min(radius * 2, 450.0);
        // El tamaño total del widget incluye los elementos orbitales
        // Se aumentó el factor de 1.3 a 1.45 para evitar overflow/clipping en Android
        final double totalWidgetSize = wheelSize * 1.45;

        return SizedBox(
          width: totalWidgetSize,
          height: totalWidgetSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Capa del CustomPainter (Reloj Técnico) - Con RepaintBoundary para reactividad inmediata
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: Size(totalWidgetSize, totalWidgetSize),
                      painter: _CircadianPainter(
                        context: widget.context, // Usar widget.context
                        baseRadius: radius,
                        fastingColor:
                            widget.zoneColor ?? const Color(0xFF00E5FF),
                        feedingColor: const Color(0xFFFFD600),
                        isRestingWarning: widget.isRestingWarning,
                        pulseOpacity:
                            _pulseAnimation.value, // Nueva opacidad pulsante
                      ),
                    ),
                  );
                },
              ),

              // 2. Iconos de Hitos con Jerarquía Visual (Geometría Dinámica)
              ...allMilestones.map((milestone) {
                final isPast = milestone.hour < currentProgress;
                final isActive = activeMilestone == milestone;

                return _PositionedIcon(
                  milestone: milestone,
                  isPast: isPast,
                  isActive: isActive,
                  radius:
                      radius -
                      7, // Alineado con el centro del arco (strokeWidth=14)
                  wheelSize: wheelSize,
                );
              }),

              // 3. Bloque Central Digital (Jerarquía Unificada y Escalable)
              SizedBox(
                width: wheelSize * 0.6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timer Principal (Escala Responsiva)
                      Text(
                        widget.durationStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: wheelSize * 0.12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),

                      SizedBox(height: wheelSize * 0.02),

                      // BOTÓN / PASTILLA DE ESTADO
                      if (widget.isRestingWarning)
                        _AvisoResting()
                      else
                        _SubLabelTag(
                          label: displayStatusLabel, // Usar label dinámico
                          color: mainColor,
                          wheelSize: wheelSize,
                        ),

                      SizedBox(height: wheelSize * 0.015),

                      // Fase Metabólica
                      Text(
                        widget.subLabel.toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: math.max(8.0, wheelSize * 0.025),
                          color: Colors.white24,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Decoración Interior (Blueprint Line Dinámica) - Eliminada para dar "aire"
            ],
          ),
        );
      },
    );
  }
}

class _SubLabelTag extends StatelessWidget {
  final String label;
  final Color color;
  final double wheelSize;

  const _SubLabelTag({
    required this.label,
    required this.color,
    required this.wheelSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: wheelSize * 0.04,
        vertical: wheelSize * 0.012,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(wheelSize * 0.04),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.robotoMono(
          fontSize: math.max(8.0, wheelSize * 0.025),
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _AvisoResting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        'RECOMENDACIÓN: ESTABILIZACIÓN HORMONAL EN CURSO',
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoMono(
          fontSize: 7,
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PositionedIcon extends StatelessWidget {
  final MetabolicMilestone milestone;
  final bool isPast;
  final bool isActive;
  final double radius;
  final double wheelSize;

  const _PositionedIcon({
    required this.milestone,
    required this.isPast,
    required this.isActive,
    required this.radius,
    required this.wheelSize,
  });

  String _formatRealTime(double decimalHour) {
    // Manejar el wrap-around de 24h
    double h = decimalHour % 24.0;
    int hour = h.floor();
    int min = ((h - hour) * 60).round();
    if (min == 60) {
      hour = (hour + 1) % 24;
      min = 0;
    }
    return "${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} HS";
  }

  @override
  Widget build(BuildContext context) {
    final angle = milestone.angle;
    final bool isMeal = milestone.label.contains('COMIDA');

    // Jerarquía de Opacidad y Color
    double opacity = 0.6; // Futuro
    if (isPast) opacity = 0.25;
    if (isActive) opacity = 1.0;

    final Color baseColor = isMeal
        ? const Color(0xFFFFD600)
        : const Color(0xFF00E5FF);
    final Color color = baseColor.withValues(alpha: opacity);

    final double sizeMultiplier = isActive ? 1.25 : 1.0;

    return Transform.translate(
      offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
      child: Tooltip(
        message:
            '${milestone.label}\n${_formatRealTime(milestone.absoluteHour)}',
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          padding: EdgeInsets.all(isActive ? 6 : 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isActive ? 2.0 : 1.0),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Icon(
            milestone.icon,
            color: color,
            size: (radius * 0.15) * sizeMultiplier,
          ),
        ),
      ),
    );
  }
}

class _CircadianPainter extends CustomPainter {
  final MetabolicContext context;
  final Color fastingColor;
  final Color feedingColor;
  final bool isRestingWarning;
  final double baseRadius;
  final double pulseOpacity;

  _CircadianPainter({
    required this.context,
    required this.baseRadius,
    required this.fastingColor,
    required this.feedingColor,
    this.isRestingWarning = false,
    this.pulseOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    const baseAngle = -math.pi / 2;
    final startHour = context.startHour;
    final startAngle = baseAngle + (startHour * 2 * math.pi / 24.0);
    final activeRadius = baseRadius - (strokeWidth / 2);
    final isFeeding = context.isFeeding;

    // 0. Preparación de Hitos
    final mealMilestones = context.mealMilestones;
    if (mealMilestones.isEmpty) return;

    final startFeedingAngle = mealMilestones.first.angle;
    final endFeedingAngle = mealMilestones.last.angle;

    double feedingSweep = endFeedingAngle - startFeedingAngle;
    if (feedingSweep < 0) feedingSweep += 2 * math.pi;

    double fastingSweep = startFeedingAngle - startAngle;
    if (fastingSweep < 0) fastingSweep += 2 * math.pi;

    final rect = Rect.fromCircle(center: center, radius: activeRadius);

    // 1. ANILLO DE FONDO SEGMENTADO (ESTÁTICO)
    // Fondo de Ayuno (Gris Tenue)
    final fastingBgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle, fastingSweep, false, fastingBgPaint);

    // Fondo de Alimentación (Gris Cálido)
    final feedingBgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      rect,
      startFeedingAngle,
      feedingSweep,
      false,
      feedingBgPaint,
    );

    // 2. PROGRESO DINÁMICO (Sincronizado con FastingState)
    final double fastingProgress =
        (context.fastingStatus?.fastingPercent ?? 0.0) / 100.0;
    final double feedingProgress =
        (context.fastingStatus?.feedingPercent ?? 0.0) / 100.0;

    // Pinturas de Progreso
    final activeFastingPaint = Paint()
      ..color = fastingColor.withValues(alpha: isFeeding ? 0.3 : 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activeFeedingPaint = Paint()
      ..color = (context.isWindowClosing && isFeeding)
          ? feedingColor.withValues(alpha: pulseOpacity)
          : feedingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isFeeding) {
      // Dibujar ayuno completado
      canvas.drawArc(rect, startAngle, fastingSweep, false, activeFastingPaint);

      // Dibujar progreso de alimentación
      if (feedingProgress > 0) {
        canvas.drawArc(
          rect,
          startFeedingAngle,
          feedingSweep * feedingProgress.clamp(0.0, 1.0),
          false,
          activeFeedingPaint,
        );

        // Glow Alimentación
        final glow = Paint()
          ..color = (context.isWindowClosing && isFeeding)
              ? feedingColor.withValues(alpha: pulseOpacity * 0.4)
              : feedingColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 4.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(
          rect,
          startFeedingAngle,
          feedingSweep * feedingProgress.clamp(0.0, 1.0),
          false,
          glow,
        );
      }
    } else {
      // Dibujar progreso de ayuno CON ZONAS METABÓLICAS
      if (fastingProgress > 0) {
        final totalFastingSweep =
            fastingSweep * fastingProgress.clamp(0.0, 1.0);
        final fastingElapsed = context.fastingStatus?.elapsed ?? Duration.zero;
        final plannedHours = context.fastingStatus?.plannedHours ?? 16;
        final totalPlannedMinutes = plannedHours * 60.0;

        // MetabolicZone thresholds in hours
        final zoneThresholds = <double>[0, 12, 18, 24, 48, 72];
        final zones = <MetabolicZone>[
          MetabolicZone.postAbsorption,
          MetabolicZone.glycogenDepletion,
          MetabolicZone.fatBurning,
          MetabolicZone.deepKetosis,
          MetabolicZone.autophagy,
          MetabolicZone.survivalMode,
        ];

        final elapsedMinutes = fastingElapsed.inMinutes.toDouble();

        // Ensure we don't exceed total sweep
        double accumulatedSweep = 0;

        for (int z = 0; z < zones.length; z++) {
          final zoneStartH = zoneThresholds[z];
          final zoneEndH = z + 1 < zoneThresholds.length
              ? zoneThresholds[z + 1]
              : 100.0; // beyond practical fasting
          final zoneStartMin = zoneStartH * 60;
          final zoneEndMin = zoneEndH * 60;

          // Only draw if we've reached this zone
          if (elapsedMinutes <= zoneStartMin) break;

          final segmentStartMin = zoneStartMin;
          final segmentEndMin = elapsedMinutes.clamp(zoneStartMin, zoneEndMin);
          if (segmentEndMin <= segmentStartMin) continue;

          // Convert to sweep angle proportions
          final segStart = (segmentStartMin / totalPlannedMinutes).clamp(
            0.0,
            1.0,
          );
          final segEnd = (segmentEndMin / totalPlannedMinutes).clamp(0.0, 1.0);
          final segStartAngle = startAngle + fastingSweep * segStart;
          final segSweepAngle = fastingSweep * (segEnd - segStart);

          if (segSweepAngle <= 0 || accumulatedSweep >= totalFastingSweep)
            continue;

          final zoneColor = zones[z].color;

          // Zone arc
          canvas.drawArc(
            rect,
            segStartAngle,
            segSweepAngle,
            false,
            Paint()
              ..color = zoneColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round,
          );

          // Zone glow
          canvas.drawArc(
            rect,
            segStartAngle,
            segSweepAngle,
            false,
            Paint()
              ..color = zoneColor.withValues(alpha: 0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth + 4.0
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );

          accumulatedSweep += segSweepAngle;
        }

        // Phase icon indicators at zone boundaries on the arc
        for (int z = 1; z < zoneThresholds.length; z++) {
          final thresholdMin = zoneThresholds[z] * 60;
          if (thresholdMin >= totalPlannedMinutes ||
              thresholdMin >= elapsedMinutes)
            break;

          final ratio = (thresholdMin / totalPlannedMinutes).clamp(0.0, 1.0);
          final markerAngle = startAngle + fastingSweep * ratio;
          final markerPos = Offset(
            center.dx + activeRadius * math.cos(markerAngle),
            center.dy + activeRadius * math.sin(markerAngle),
          );

          // Small diamond marker at zone transitions
          canvas.drawCircle(
            markerPos,
            3,
            Paint()..color = Colors.white.withValues(alpha: 0.8),
          );
        }
      }
    }

    // 3. INDICADOR "AHORA" (Punto Brillante 24h)
    final now = DateTime.now();
    final double currentHourFloat = now.hour + (now.minute / 60.0);
    final double nowAngle =
        (currentHourFloat * 2 * math.pi / 24.0) - (math.pi / 2.0);

    final nowPaint = Paint()..color = Colors.white;
    final nowGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final Offset nowPos = Offset(
      center.dx + activeRadius * math.cos(nowAngle),
      center.dy + activeRadius * math.sin(nowAngle),
    );

    canvas.drawCircle(nowPos, 6, nowGlow);
    canvas.drawCircle(nowPos, 4, nowPaint);

    // 4. Marcadores de Minutos (Ticks) en la periferia
    final double totalDayProgress =
        (now.hour * 3600 + now.minute * 60 + now.second) / (24 * 3600);
    final progressColor = isFeeding ? feedingColor : fastingColor;

    // Aplicar opacidad de pulso solo si estamos en cierre de ventana y en alimentación
    final activeColor = (context.isWindowClosing && isFeeding)
        ? progressColor.withValues(alpha: pulseOpacity)
        : progressColor;
    _drawTicks(canvas, center, activeRadius, totalDayProgress, activeColor);

    // 5. Marcadores de Hora Fijos
    _drawFixedTimeMarkers(canvas, center, baseRadius);
  }

  void _drawFixedTimeMarkers(Canvas canvas, Offset center, double radius) {
    const hours = {0: "00:00", 6: "06:00", 12: "12:00", 18: "18:00"};
    final markerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
      ..strokeWidth = 2.0;

    for (var entry in hours.entries) {
      final angle = (entry.key * 2 * math.pi / 24) - math.pi / 2;
      final r1 = radius + (radius * 0.05);
      final r2 = radius + (radius * 0.08);
      canvas.drawLine(
        Offset(
          center.dx + r1 * math.cos(angle),
          center.dy + r1 * math.sin(angle),
        ),
        Offset(
          center.dx + r2 * math.cos(angle),
          center.dy + r2 * math.sin(angle),
        ),
        markerPaint,
      );

      final rLabel = radius + (radius * 0.16);
      final offset = Offset(
        center.dx + rLabel * math.cos(angle),
        center.dy + rLabel * math.sin(angle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: GoogleFonts.robotoMono(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
            fontSize: math.max(7.0, radius * 0.08),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawTicks(
    Canvas canvas,
    Offset center,
    double radius,
    double totalProgress,
    Color activeColor,
  ) {
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.0;
    final activeTickPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const int count = 90;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi / count) - math.pi / 2;
      final rInner = radius + 14.0;
      final rOuter = rInner + (i % 5 == 0 ? 8.0 : 4.0);
      final p1 = Offset(
        center.dx + rInner * math.cos(angle),
        center.dy + rInner * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + rOuter * math.cos(angle),
        center.dy + rOuter * math.sin(angle),
      );

      if (i / count <= totalProgress) {
        canvas.drawLine(p1, p2, activeTickPaint);
        final glow = Paint()
          ..color = activeColor.withValues(alpha: 0.2)
          ..strokeWidth = 4.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(p1, p2, glow);
      } else {
        canvas.drawLine(p1, p2, tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CircadianPainter oldDelegate) => true;
}
