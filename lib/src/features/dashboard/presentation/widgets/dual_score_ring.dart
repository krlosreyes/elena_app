// SPEC-170 §RF-170-01 (2026-06-04): widget de los dos rings adyacentes
// HOY + IMR en el header del Dashboard.
//
// Reemplaza el número grande "87 /100" del card "TU DÍA" por dos rings
// adyacentes con el score de cada métrica + label + sub-label.
//
// Stateless puro, sin Riverpod — testeable directo con widget tests.
// El caller (dashboard_screen.dart) le inyecta los scores ya resueltos
// vía displayDailyScoreProvider + displayedImrProvider.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Color del ring IMR. Cyan complementario al teal del accent (HOY).
/// Sin alias en AppColors por ahora — si tras validación visual Carlos
/// lo aprueba, se promueve a token canónico. Inspiración: Tailwind
/// cyan-500 con leve desaturación para encajar con el dark theme.
const Color _kImrColor = Color(0xFF22D3EE);

class DualScoreRing extends StatelessWidget {
  const DualScoreRing({
    super.key,
    required this.dailyScore,
    required this.dailyDelta,
    required this.imrScore,
    required this.onTap,
  });

  /// Score del Día 0-100 (display anclado al ciclo metabólico — SPEC-171).
  final int dailyScore;

  /// Delta vs ayer (o vs último ciclo cerrado). Null si no hay día previo.
  final int? dailyDelta;

  /// IMR longitudinal 0-100 (displayedImrProvider).
  final int imrScore;

  /// Abre el ExplainerSheet único que cubre ambos.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // SPEC-170 §R-02: rings más chicos en pantallas estrechas
          // (iPhone SE 320px). Default 72px, fallback 60px <360.
          final double ringSize = constraints.maxWidth < 360 ? 60 : 72;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BigScoreRing(
                score: dailyScore,
                color: AppColors.metabolicGreen,
                label: 'HOY',
                sublabel: _dailyDeltaLabel(dailyDelta),
                size: ringSize,
              ),
              _BigScoreRing(
                score: imrScore,
                color: _kImrColor,
                label: 'IMR',
                sublabel: 'tu base',
                size: ringSize,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Sublabel del HOY: "↑5 vs ayer", "↓3 vs ayer", o " " (espacio) si null.
  /// Devolvemos espacio en vez de null para que ambos rings mantengan
  /// la misma altura — evita layout shift cuando aparece/desaparece el
  /// delta.
  static String _dailyDeltaLabel(int? delta) {
    if (delta == null) return ' ';
    if (delta == 0) return 'igual que ayer';
    final arrow = delta > 0 ? '↑' : '↓';
    return '$arrow${delta.abs()} vs ayer';
  }
}

/// Ring grande con el score numérico en el centro + label y sub-label
/// debajo. Privado al archivo — no se reusa fuera del DualScoreRing.
class _BigScoreRing extends StatelessWidget {
  const _BigScoreRing({
    required this.score,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.size,
  });

  final int score;
  final Color color;
  final String label;
  final String sublabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
