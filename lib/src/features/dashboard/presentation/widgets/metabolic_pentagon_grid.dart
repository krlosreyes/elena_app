import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/metabolic_hub_provider.dart';
import '../../../fasting/application/fasting_controller.dart';
import '../../../training/presentation/exercise_tracking_view.dart';
import '../../../training/application/training_controller.dart';

class MetabolicPentagonGrid extends ConsumerStatefulWidget {
  final Map<int, GlobalKey>? pilarKeys;
  const MetabolicPentagonGrid({super.key, this.pilarKeys});

  @override
  ConsumerState<MetabolicPentagonGrid> createState() =>
      _MetabolicPentagonGridState();
}

class _MetabolicPentagonGridState extends ConsumerState<MetabolicPentagonGrid>
    with TickerProviderStateMixin {
  int? _activeSegment;
  late AnimationController _animController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(Offset localPos, double size, double radius) {
    final center = Offset(size / 2, size / 2);
    final delta = localPos - center;
    final dist = delta.distance;

    if (dist < radius) return;

    double angle = math.atan2(delta.dy, delta.dx);
    double degrees = angle * 180 / math.pi;

    int segmentIndex = -1;
    if (degrees < -126) degrees += 360;

    if (degrees >= -126 && degrees < -54) {
      segmentIndex = 0; // Top
    } else if (degrees >= -54 && degrees < 18) {
      segmentIndex = 1; // Top Right
    } else if (degrees >= 18 && degrees < 90) {
      segmentIndex = 2; // Bottom Right
    } else if (degrees >= 90 && degrees < 162) {
      segmentIndex = 3; // Bottom Left
    } else if (degrees >= 162 && degrees <= 234) {
      segmentIndex = 4; // Top Left
    }

    if (segmentIndex != -1) {
      _triggerSegment(segmentIndex);
    }
  }

  void _triggerSegment(int index) {
    setState(() => _activeSegment = index);
    _animController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _activeSegment = null);
      });
    });

    final routes = [
      '/fasting_details',
      '/exercise_log',
      '/nutrition_log', // Nutrición → RegistroNutricionScreen
      '/sleep_analysis',
      '/hydration_tracker',
    ];

    context.push(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    // 🎧 Escuchar completado de ejercicio para pulso neón
    ref.listen<bool>(exerciseJustCompletedProvider, (prev, next) {
      if (next == true) {
        setState(() => _activeSegment = 1); // 1 = Ejercicio
        _animController.forward(from: 0).then((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _activeSegment = null);
            // Reset provider so it can trigger again
            ref.read(exerciseJustCompletedProvider.notifier).state = false;
          });
        });
      }
    });

    final hub = ref.watch(metabolicHubProvider);
    if (hub.profile == null) return const SizedBox.shrink();

    final bool isPrediabetes =
        hub.profile?.pathologies.any((p) => p.toLowerCase() == 'prediabetes') ??
            false;

    // Use responsive calculation instead of LayoutBuilder to avoid intrinsics issues in Web
    final double screenWidth = MediaQuery.of(context).size.width;

    // Ajustes de Escala según Ancho (Mobile vs Tablet)
    final double baseSize = screenWidth.clamp(320.0, 600.0);
    final double size = baseSize * 0.9; // 90% del ancho para margen interno

    // Incremento de tamaño solicitado por el usuario solo para Android
    final bool isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final double radiusMultiplier = isAndroid ? 1.25 : 1.0;
    final double radius =
        (size * 0.145) * radiusMultiplier; // Radio base escalado

    // Provide fast and training states directly from build method to ensure valid UI rebuild
    final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
    final trainingState = ref.watch(trainingControllerProvider);

    return GestureDetector(
      onTapUp: (details) => _handleTap(details.localPosition, size, radius),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: screenWidth,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: PentagonalSegmentsPainter(
                  pentagonRadius: radius,
                  accentColor: AppTheme.primary,
                  activeSegment: _activeSegment,
                  highlightOpacity: 1.0 - _animController.value,
                  highlightPrediabetes: isPrediabetes,
                ),
              ),
              _buildCenterPentagon(hub, radius, radiusMultiplier, isAndroid),
              ..._buildSegmentContents(hub, size, radius, fastingState, trainingState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPentagon(MetabolicContext hub, double radius,
      double radiusMultiplier, bool isAndroid) {
    return Container(
      width: radius * 2.25, // Optimized factor for 0.165 radius
      height: radius * 2.25,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ShapeDecoration(
        color: const Color(0xFF0A0A0A),
        shape: const PentagonBorder(sideColor: Colors.orange, strokeWidth: 1.2),
        shadows: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hub.totalIED.toStringAsFixed(1),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: (40 * (isAndroid ? 0.72 : 1.0)).toDouble(),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              'IED',
              style: GoogleFonts.jetBrainsMono(
                fontSize: (16 * (isAndroid ? 0.72 : 1.0)).toDouble(),
                fontWeight: FontWeight.w600, // SemiBold
                color: Colors.orange,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSegmentContents(
      MetabolicContext hub,
      double size,
      double radius,
      FastingState? fastingState,
      TrainingStatusState trainingState) {
    
    final isFeeding = fastingState?.isFeeding ?? false;
    final fastingPercent = isFeeding
        ? (fastingState?.feedingPercent ?? 0.0).clamp(0.0, 100.0)
        : (fastingState?.fastingPercent ?? 0.0).clamp(0.0, 100.0);
    final fastingTitle = isFeeding ? 'VENTANA DE\nALIMENTACIÓN' : 'AYUNO';

    final hydrationGoal = 10;
    final hydrationCount = hub.hydrationLevel.toInt();
    final hydrationPercent = (hydrationCount / hydrationGoal) * 100;

    final activeTrainingMinutes = trainingState.isTimerRunning ? (trainingState.elapsedSeconds / 60.0) : 0.0;

    final double exerciseGoal = 30.0; // Sincronizado con UI (30 min = 100%)
    final totalExMinutes = (hub.movementStatus?.minutesCurrent ?? 0) + activeTrainingMinutes;
    final exercisePercent = (totalExMinutes / exerciseGoal) * 100;

    // Mostrar décimas si está activo para un feedback más "tiempo real" y evitar sensación de "pegado"
    final exerciseDisplayValue = trainingState.isTimerRunning 
        ? '${exercisePercent.toStringAsFixed(1)}%'
        : '${exercisePercent.toStringAsFixed(0)}%';

    final List<Map<String, dynamic>> segmentConfigs = [
      {
        'title': fastingTitle,
        'value': '${fastingPercent.toStringAsFixed(0)}%',
        'icon': isFeeding ? Icons.restaurant_rounded : Icons.timer_outlined,
        'angle': -math.pi / 2,
      },
      {
        'title': 'EJERCICIO',
        'value': exerciseDisplayValue,
        'icon': Icons.fitness_center_outlined,
        'angle': -math.pi / 2 + (2 * math.pi / 5),
      },
      {
        'title': 'NUTRICIÓN',
        'value': '${hub.nutritionScore.toStringAsFixed(0)}%',
        'icon': Icons.restaurant_outlined,
        'angle': -math.pi / 2 + (4 * math.pi / 5),
      },
      {
        'title': 'SUEÑO',
        'value': '${(hub.sleepMinutes / 60).toStringAsFixed(1)}H',
        'icon': Icons.bedtime_outlined,
        'angle': -math.pi / 2 + (6 * math.pi / 5),
      },
      {
        'title': 'HIDRATACIÓN',
        'value': '${hydrationPercent.toStringAsFixed(0)}%',
        'icon': Icons.water_drop_outlined,
        'angle': -math.pi / 2 + (8 * math.pi / 5),
      },
    ];

    return segmentConfigs.asMap().entries.map((entry) {
      final config = entry.value;
      final angle = config['angle'] as double;

      // EXPANSIÓN ORBITAL RELATIVA
      // Fine-tuning: 15% closer than previous iteration for better balance
      final bool isAndroid =
          Theme.of(context).platform == TargetPlatform.android;
      final double orbitMultiplier = isAndroid ? (2.625 * 0.85) : 2.1;
      final orbitDist = radius * orbitMultiplier;
      final x = size / 2 + orbitDist * math.cos(angle);
      final y = size / 2 + orbitDist * math.sin(angle);

      final String fullValue = config['value'] as String;
      final bool isSleep = config['title'] == 'SUEÑO';
      final bool highQualitySleep = isSleep && hub.lastSleepScore > 80;

      return Positioned(
        left: x - 50,
        top: y - 35,
        width: 100,
        child: Container(
          key: widget.pilarKeys?[entry.key],
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulseValue =
                        highQualitySleep ? _pulseController.value : 0.0;
                    return Icon(
                      config['icon'],
                      color: Color.lerp(
                          AppTheme.primary, Colors.greenAccent, pulseValue),
                      size: 26 + (pulseValue * 4),
                      shadows: [
                        if (highQualitySleep)
                          Shadow(
                            color: Colors.greenAccent
                                .withValues(alpha: 0.5 * pulseValue),
                            blurRadius: 15 * pulseValue,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 1),
                Text(
                  config['title'],
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: isFeeding && config['title'].contains('\n') ? 9 : 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fullValue,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18, // Reducido a 18px (de 24px)
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class PentagonalSegmentsPainter extends CustomPainter {
  final double pentagonRadius;
  final Color accentColor;
  final int? activeSegment;
  final double highlightOpacity;
  final bool highlightPrediabetes;

  PentagonalSegmentsPainter({
    required this.pentagonRadius,
    required this.accentColor,
    this.activeSegment,
    this.highlightOpacity = 0.0,
    this.highlightPrediabetes = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.05);

    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 5) - (math.pi / 5);
      final outerPoint = center +
          Offset(math.cos(angle) * size.width, math.sin(angle) * size.height);

      if (highlightPrediabetes && (i == 1 || i == 2)) {
        final highlightPaint = Paint()
          ..color = Colors.orange.withValues(alpha: 0.05)
          ..style = PaintingStyle.fill;
        final nextAngle = angle + (2 * math.pi / 5);
        final path = Path();
        path.moveTo(center.dx, center.dy);
        path.lineTo(center.dx + math.cos(angle) * size.width,
            center.dy + math.sin(angle) * size.height);
        path.lineTo(center.dx + math.cos(nextAngle) * size.width,
            center.dy + math.sin(nextAngle) * size.height);
        path.close();
        canvas.drawPath(path, highlightPaint);
      }

      canvas.drawLine(center, outerPoint, paint);
    }

    if (activeSegment != null) {
      _drawHighlight(canvas, size, center);
    }

    final pentagonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.orange.withValues(alpha: 0.4);

    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final x = center.dx + pentagonRadius * math.cos(angle);
      final y = center.dy + pentagonRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, pentagonPaint);
  }

  void _drawHighlight(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = accentColor.withValues(alpha: 0.15 * highlightOpacity);

    final highlightPath = Path();
    final i = activeSegment;
    if (i == null) return;

    final startAngle = -math.pi / 2 + (i * 2 * math.pi / 5) - (math.pi / 5);
    final endAngle = startAngle + (2 * math.pi / 5);

    highlightPath.moveTo(center.dx, center.dy);

    const double outerDist = 1000.0;
    highlightPath.lineTo(
      center.dx + outerDist * math.cos(startAngle),
      center.dy + outerDist * math.sin(startAngle),
    );
    highlightPath.lineTo(
      center.dx + outerDist * math.cos(endAngle),
      center.dy + outerDist * math.sin(endAngle),
    );
    highlightPath.close();

    final pentagonClip = Path();
    for (int j = 0; j < 5; j++) {
      final angle = -math.pi / 2 + (j * 2 * math.pi / 5);
      final x = center.dx + pentagonRadius * math.cos(angle);
      final y = center.dy + pentagonRadius * math.sin(angle);
      if (j == 0) {
        pentagonClip.moveTo(x, y);
      } else {
        pentagonClip.lineTo(x, y);
      }
    }
    pentagonClip.close();

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(
      Path.combine(PathOperation.difference, highlightPath, pentagonClip),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PentagonalSegmentsPainter oldDelegate) =>
      oldDelegate.activeSegment != activeSegment ||
      oldDelegate.highlightOpacity != highlightOpacity;
}

class PentagonBorder extends ShapeBorder {
  final Color sideColor;
  final double strokeWidth;

  const PentagonBorder({required this.sideColor, required this.strokeWidth});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(strokeWidth), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final r = rect.width / 2;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 5);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = sideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
