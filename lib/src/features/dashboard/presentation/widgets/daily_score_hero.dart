// Reemplaza a `DualScoreRing` (SPEC-170) en la card "PROGRESO HOY" del
// Dashboard.
//
// Decisión de producto (22-jul, líder de proyecto): el IMR longitudinal
// deja de comunicarse en el Dashboard — vive solo en Perfil y en la
// gráfica de "Resultados" de la pestaña Progreso, para no diluir el
// mensaje del día con una métrica de ritmo distinto (semanal/mensual).
// Sacar el segundo ring sin más dejaba el ring "HOY" descentrado y la
// card con la mitad superior vacía.
//
// Investigación rápida de patrones en apps de salud comparables (Apple
// Fitness, Oura, Whoop): cuando se baja de dos anillos a uno, el segundo
// espacio casi nunca se llena con OTRO número (eso repite el problema
// que motivó sacar el IMR de acá) — se usa para dar CONTEXTO de dónde
// sale el número que ya se está mostrando. Acá el contexto es literal:
// los 5 pilares que ya se ven en detalle más abajo en la misma card.
// Tocar el ring o el puente de iconos abre el mismo explainer sheet de
// siempre (ahora solo sobre HOY, ver daily_score_explainer_sheet.dart).

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Ícono + color de cada uno de los 5 pilares — mismos valores que
/// `DashboardPillarsRow` usa para sus `PillarRing`. Deliberadamente sin
/// progreso ni porcentaje acá: es un puente visual ("de esto sale tu
/// número"), no una segunda fuente de verdad — el detalle real con
/// progreso vive en la fila de pilares, un scroll más abajo en la misma
/// card.
const List<(IconData, Color)> _kPillarBridgeIcons = [
  (Icons.timer_rounded, AppColors.metabolicGreen), // Ayuno
  (Icons.nightlight_round, Color(0xFF818CF8)), // Sueño
  (Icons.water_drop_rounded, Colors.blueAccent), // Hidratación
  (Icons.fitness_center_rounded, Colors.tealAccent), // Ejercicio
  (Icons.restaurant_rounded, Colors.orangeAccent), // Comidas
];

class DailyScoreHero extends StatelessWidget {
  const DailyScoreHero({
    super.key,
    required this.dailyScore,
    required this.dailyDelta,
    required this.onTap,
  });

  /// Score del Día 0-100 (display anclado al ciclo metabólico — SPEC-171).
  final int dailyScore;

  /// Delta vs ayer (o vs último ciclo cerrado). Null si no hay día previo.
  final int? dailyDelta;

  /// Abre el ExplainerSheet de HOY.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _dailySemanticLabel(dailyScore, dailyDelta),
      hint: 'Toca para ver cómo se arma tu puntaje de hoy',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool narrow = constraints.maxWidth < 340;
            final double ringSize = narrow ? 96 : 112;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BigScoreRing(
                  score: dailyScore,
                  sublabel: _dailyDeltaLabel(dailyDelta),
                  size: ringSize,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TU DÍA SE ARMA CON',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _kPillarBridgeIcons
                            .map((p) => _PillarBridgeDot(icon: p.$1, color: p.$2))
                            .toList(),
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

  static String _dailyDeltaLabel(int? delta) {
    if (delta == null) return ' ';
    if (delta == 0) return 'igual que ayer';
    final arrow = delta > 0 ? '↑' : '↓';
    return '$arrow${delta.abs()} vs ayer';
  }

  static String _dailySemanticLabel(int score, int? delta) {
    final base = 'Puntaje de hoy: $score de 100';
    if (delta == null) return base;
    if (delta == 0) return '$base, igual que ayer';
    if (delta > 0) return '$base, subió $delta respecto a ayer';
    return '$base, bajó ${delta.abs()} respecto a ayer';
  }
}

/// Ring grande con el score numérico en el centro + label "HOY" + sub-label
/// (delta vs ayer) debajo. Idéntico visualmente al hero de `DualScoreRing`
/// — solo se le subió el tamaño por default al no tener ya un segundo ring
/// al lado empujándolo.
class _BigScoreRing extends StatelessWidget {
  const _BigScoreRing({
    required this.score,
    required this.sublabel,
    required this.size,
  });

  final int score;
  final String sublabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);
    const color = AppColors.metabolicGreen;
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
                  strokeWidth: 5,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.34,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'HOY',
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

/// Punto pequeño del puente visual: ícono de un pilar en un círculo
/// tenue de su propio color. Sin progreso ni número — el detalle real
/// vive en `PillarRing`, en la fila de abajo.
class _PillarBridgeDot extends StatelessWidget {
  const _PillarBridgeDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Icon(icon, size: 14, color: color.withValues(alpha: 0.85)),
    );
  }
}
