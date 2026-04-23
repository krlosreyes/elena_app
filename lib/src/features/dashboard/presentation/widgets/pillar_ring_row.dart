// SPEC-19: Panel Interactivo de Pilares
//
// Los anillos actúan como menú de selección de pilar.
// El anillo seleccionado muestra glow + borde brillante.
// Tap en anillo → callback onSelected(index), sin navegar.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:elena_app/src/core/constants/pillar_constants.dart';

class PillarRingRow extends StatelessWidget {
  const PillarRingRow({
    super.key,
    required this.fastingProgress,
    required this.sleepProgress,
    required this.hydrationProgress,
    required this.exerciseProgress,
    required this.nutritionProgress,
    required this.selectedIndex,
    required this.onSelected,
  });

  final double fastingProgress;
  final double sleepProgress;
  final double hydrationProgress;
  final double exerciseProgress;
  final double nutritionProgress;

  /// Índice del pilar seleccionado (0=Ayuno, 1=Sueño, 2=Hidra, 3=Ejercicio, 4=Nutrición)
  final int selectedIndex;

  /// Callback cuando el usuario toca un anillo
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final pillars = [
      _PillarData('⏱️', fastingProgress,  PillarConstants.colors[PillarConstants.pilarAyuno]!,   'Ayuno'),
      _PillarData('🌙', sleepProgress,     PillarConstants.colors[PillarConstants.pilarSoporte]!, 'Sueño'),
      _PillarData('💧', hydrationProgress, const Color(0xFF38BDF8),                               'Hidratación'),
      _PillarData('💪', exerciseProgress,  PillarConstants.colors[PillarConstants.pilarEjercicio]!, 'Ejercicio'),
      _PillarData('🥦', nutritionProgress, PillarConstants.colors[PillarConstants.pilarNutricion]!, 'Comidas'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(pillars.length, (i) {
          return GestureDetector(
            onTap: () => onSelected(i),
            child: _PillarRing(
              data: pillars[i],
              isSelected: i == selectedIndex,
            ),
          );
        }),
      ),
    );
  }
}

class _PillarData {
  final String emoji;
  final double progress;
  final Color  color;
  final String label;
  const _PillarData(this.emoji, this.progress, this.color, this.label);
}

class _PillarRing extends StatelessWidget {
  const _PillarRing({required this.data, required this.isSelected});
  final _PillarData data;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final double p    = data.progress.clamp(0.0, 1.0);
    final bool   done = p >= 1.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 56 : 52,
          height: isSelected ? 56 : 52,
          decoration: isSelected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Anillo ───────────────────────────────────────────────────────
          CustomPaint(
            size: Size(isSelected ? 56 : 52, isSelected ? 56 : 52),
            painter: _RingPainter(
              progress: p,
              color: data.color,
              bgColor: isSelected
                  ? data.color.withOpacity(0.18)
                  : Colors.white.withOpacity(0.07),
              strokeWidth: isSelected ? 4.0 : 3.5,
            ),
          ),

          // ── Emoji ────────────────────────────────────────────────────────
          Text(
            data.emoji,
            style: TextStyle(fontSize: isSelected ? 21 : 19),
          ),

          // ── Check completado ─────────────────────────────────────────────
          if (done)
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 9, color: Colors.white),
              ),
            ),
        ],
      ),
        ), // AnimatedContainer
        const SizedBox(height: 5),
        // ── Label ──────────────────────────────────────────────────────────
        Text(
          data.label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? data.color
                : Colors.white.withOpacity(0.35),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color  color;
  final Color  bgColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect, -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.strokeWidth != strokeWidth;
}
