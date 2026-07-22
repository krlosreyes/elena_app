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
// v1 del "puente visual" (commit b393b38, mismo día): 5 íconos de
// pilares sin progreso ("TU DÍA SE ARMA CON"). Carlos lo señaló como
// redundante apenas lo vio en pantalla — esos mismos 5 íconos, CON
// progreso real, ya están un scroll más abajo en la misma card
// (`DashboardPillarsRow`). Mostrarlos dos veces no agrega información,
// solo repite.
//
// v2 (22-jul, misma sesión): en vez de decorar el mismo concepto dos
// veces, se usa el espacio para un dato que esta card todavía no
// mostraba en ningún lado — la racha de días consecutivos. Esto
// además resuelve una segunda redundancia que Carlos pidió cerrar en
// el mismo cambio: la racha vivía ADEMÁS como badge propio en el header
// del Dashboard (`ElenaHeader._StreakBadge`, commit fb32b03, "un solo
// indicador"). Con la racha acá, ese badge del header sobra — se quita
// en `elena_header.dart` en el mismo commit. Resultado: un solo lugar
// para la racha (acá), un solo lugar para el detalle de pilares con
// progreso (la fila de abajo).
//
// Tocar el ring abre el explainer sheet de siempre (ahora solo sobre
// HOY, ver daily_score_explainer_sheet.dart). Tocar el bloque de racha
// navega directo a `RachaDetailScreen` (`/analysis/racha`) — mismo
// destino que tenía el badge del header que reemplaza.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class DailyScoreHero extends StatelessWidget {
  const DailyScoreHero({
    super.key,
    required this.dailyScore,
    required this.dailyDelta,
    required this.onTap,
    required this.streakDays,
    this.streakProtected = false,
  });

  /// Score del Día 0-100 (display anclado al ciclo metabólico — SPEC-171).
  final int dailyScore;

  /// Delta vs ayer (o vs último ciclo cerrado). Null si no hay día previo.
  final int? dailyDelta;

  /// Abre el ExplainerSheet de HOY.
  final VoidCallback onTap;

  /// Racha de días consecutivos — mismo campo que consumía
  /// `ElenaHeader._StreakBadge` (`StreakState.currentStreak`). Ver doc
  /// de archivo: único indicador de racha de la app tras el fix del
  /// 22-jul.
  final int streakDays;

  /// SPEC-255 RF-02: true si la racha incluye un día perdonado por una
  /// reserva — mismo significado que `StreakState.streakHasProtectedDay`.
  final bool streakProtected;

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
                        'TU RACHA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StreakBridge(
                        days: streakDays,
                        protected: streakProtected,
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

/// Bloque de racha del puente visual — reemplaza a los 5 íconos de
/// pilares (ver doc de archivo). Tap PROPIO e independiente del tap
/// del ring (que abre el explainer): al estar anidado, gana el gesture
/// arena de Flutter y el tap sobre este bloque navega a
/// `RachaDetailScreen` sin disparar también el explainer del ring.
/// Mismo destino que tenía `ElenaHeader._StreakBadge`.
class _StreakBridge extends StatelessWidget {
  const _StreakBridge({required this.days, required this.protected});

  final int days;
  final bool protected;

  @override
  Widget build(BuildContext context) {
    final active = days >= 1;
    final flameColor =
        active ? Colors.orange : Colors.white.withValues(alpha: 0.35);
    final label = active
        ? '$days ${days == 1 ? "día" : "días"} de racha'
        : 'Empezá tu racha hoy';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/analysis/racha'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.local_fire_department_rounded
                : Icons.local_fire_department_outlined,
            color: flameColor,
            size: 20,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    active ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (protected) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.shield_rounded,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
              size: 13,
            ),
          ],
          const SizedBox(width: 2),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.25),
            size: 16,
          ),
        ],
      ),
    );
  }
}
