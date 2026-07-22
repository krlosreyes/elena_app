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
// v1 (commit b393b38, mismo día): 5 íconos de pilares sin progreso
// ("TU DÍA SE ARMA CON"). Carlos lo señaló como redundante apenas lo
// vio en pantalla — esos mismos 5 íconos, CON progreso real, ya están
// un scroll más abajo en la misma card (`DashboardPillarsRow`).
//
// v2 (mismo día): se cambió el bloque de íconos por una línea de texto
// con la racha ("🔥 X días de racha"). Resolvió la redundancia de
// íconos, pero le bajó protagonismo a la racha — Carlos la quería de
// vuelta como RING, en el mismo lugar físico donde antes vivía el IMR,
// pero más chico que el ring de HOY (jerarquía: HOY es el hero).
//
// v3 (22-jul, misma sesión — versión actual): ring de racha con código
// semáforo. El borde del ring no es una barra de progreso (la racha no
// tiene "0-100") — es un indicador de ESTADO: verde (racha activa y hoy
// ya calificó), amarillo (racha activa, hoy no calificó todavía, pero
// no es urgente), rojo (mismo umbral que ya usaba `streakAtRiskProvider`
// para el banner: sin reserva y ya pasadas las 18:00 sin calificar).
// Gris/neutro cuando no hay racha activa (`streakDays == 0`) — no hay
// nada que arriesgar todavía, así que no es parte del semáforo. Ver
// `StreakRiskLevel` en streak_notifier.dart — es una gradación de
// señales que YA existían de forma binaria, no un cálculo nuevo del
// motor de racha.
//
// Esto también resuelve, de paso, la segunda redundancia que Carlos
// había pedido cerrar horas antes: la racha vivía ADEMÁS como badge en
// el header (`ElenaHeader._StreakBadge`, commit fb32b03). Con la racha
// acá como ring, ese badge sobra — se quitó de `elena_header.dart`.
//
// Tocar el ring de HOY abre el explainer sheet de siempre (ver
// daily_score_explainer_sheet.dart). Tocar el ring de racha navega
// directo a `RachaDetailScreen` (`/analysis/racha`) — mismo destino que
// tenía el badge del header que reemplaza.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart'
    show StreakRiskLevel;

class DailyScoreHero extends StatelessWidget {
  const DailyScoreHero({
    super.key,
    required this.dailyScore,
    required this.dailyDelta,
    required this.onTap,
    required this.streakDays,
    required this.streakRisk,
    this.streakProtected = false,
  });

  /// Score del Día 0-100 (display anclado al ciclo metabólico — SPEC-171).
  final int dailyScore;

  /// Delta vs ayer (o vs último ciclo cerrado). Null si no hay día previo.
  final int? dailyDelta;

  /// Abre el ExplainerSheet de HOY.
  final VoidCallback onTap;

  /// Racha de días consecutivos — mismo campo que consumía
  /// `ElenaHeader._StreakBadge` (`StreakState.currentStreak`).
  final int streakDays;

  /// Nivel semáforo de la racha (`streakRiskLevelProvider`) — colorea el
  /// borde del ring. Ver doc de archivo.
  final StreakRiskLevel streakRisk;

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
            final double heroSize = narrow ? 92 : 108;
            final double streakSize = narrow ? 52 : 60;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BigScoreRing(
                  score: dailyScore,
                  sublabel: _dailyDeltaLabel(dailyDelta),
                  size: heroSize,
                ),
                SizedBox(width: narrow ? 20 : 32),
                _StreakRing(
                  days: streakDays,
                  risk: streakRisk,
                  protected: streakProtected,
                  size: streakSize,
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
/// (delta vs ayer) debajo.
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

/// Ring de racha — más chico que `_BigScoreRing` (jerarquía: HOY es el
/// hero), en el mismo lugar físico donde antes vivía el ring de IMR.
///
/// A diferencia de `_BigScoreRing`, el borde NO es una barra de
/// progreso 0-100 — la racha no tiene "porcentaje". Es un semáforo de
/// ESTADO (ver `StreakRiskLevel`): se dibuja siempre lleno (`value:
/// 1.0`), y lo que comunica es el COLOR, no cuánto se llenó.
///
/// Tap PROPIO e independiente del tap del ring de HOY (que abre el
/// explainer): al estar anidado, gana el gesture arena de Flutter y el
/// tap acá navega a `RachaDetailScreen` sin disparar también el
/// explainer. Mismo destino que tenía `ElenaHeader._StreakBadge`.
class _StreakRing extends StatelessWidget {
  const _StreakRing({
    required this.days,
    required this.risk,
    required this.protected,
    required this.size,
  });

  final int days;
  final StreakRiskLevel risk;
  final bool protected;
  final double size;

  Color get _color {
    switch (risk) {
      case StreakRiskLevel.none:
        return Colors.white.withValues(alpha: 0.28);
      case StreakRiskLevel.onTrack:
        return const Color(0xFF22C55E); // verde
      case StreakRiskLevel.atRiskMedium:
        return const Color(0xFFF59E0B); // ámbar — mismo tono que
        // StreakAtRiskBanner usaba para su único estado de aviso.
      case StreakRiskLevel.atRiskHigh:
        return const Color(0xFFEF4444); // rojo
    }
  }

  String get _stateLabel {
    switch (risk) {
      case StreakRiskLevel.none:
        return 'Arrancá hoy';
      case StreakRiskLevel.onTrack:
        return 'Vas bien';
      case StreakRiskLevel.atRiskMedium:
        return 'Sumá hoy';
      case StreakRiskLevel.atRiskHigh:
        return 'En riesgo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final active = days >= 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/analysis/racha'),
      child: Column(
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
                    value: 1.0,
                    strokeWidth: 4,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active
                          ? Icons.local_fire_department_rounded
                          : Icons.local_fire_department_outlined,
                      color: color,
                      size: size * 0.30,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$days',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                if (protected)
                  Positioned(
                    top: 0,
                    right: size * 0.08,
                    child: Icon(
                      Icons.shield_rounded,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                      size: size * 0.20,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RACHA',
            style: TextStyle(
              color: color,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _stateLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
