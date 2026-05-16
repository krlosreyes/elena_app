// SPEC-115: hero display del centro del reloj circadiano.
//
// Reemplaza el bloque "IMR SCORE / 75" original. El IMR sigue
// existiendo y se muestra en Análisis con su rediseño dedicado.
//
// Cuatro modos:
//   A) Ayuno en curso → cronómetro ascendente + próximo hito.
//   B) Ayuno completado hoy → duración total + próximo proyectado.
//   C) En ventana de alimentación → countdown a `windowEnd`.
//   D) Sin estado útil → placeholder + CTA implícito.
//
// Diseño: el contenido vive dentro del "área central segura" del reloj
// (~55% del diámetro) para no chocar con los marcadores de fase del
// aro de ayuno ni con los textos verticales del fondo de ciclos
// biológicos. FittedBox garantiza que el cronómetro siempre encaje
// aunque la fuente del sistema sea ligeramente más ancha.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/domain/eating_window_state.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';

class FastingHeroDisplay extends StatefulWidget {
  final FastingState fastingState;
  final EatingWindowState? eatingWindow;

  /// Lado (diámetro) del reloj. Define la escala de todo el contenido.
  final double size;

  const FastingHeroDisplay({
    super.key,
    required this.fastingState,
    required this.eatingWindow,
    required this.size,
  });

  @override
  State<FastingHeroDisplay> createState() => _FastingHeroDisplayState();
}

class _FastingHeroDisplayState extends State<FastingHeroDisplay> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  _Mode get _mode {
    final s = widget.fastingState;
    if (s.isActive) return _Mode.activeFasting;
    if (s.completedToday == true) return _Mode.completedToday;
    final w = widget.eatingWindow;
    if (w != null && _now.isBefore(w.windowEnd)) {
      return _Mode.eatingWindow;
    }
    return _Mode.idle;
  }

  bool get _needsTicker =>
      _mode == _Mode.activeFasting || _mode == _Mode.eatingWindow;

  @override
  void initState() {
    super.initState();
    if (_needsTicker) _startTicker();
  }

  @override
  void didUpdateWidget(covariant FastingHeroDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_needsTicker) {
      _startTicker();
    } else {
      _stopTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorBase = Theme.of(context).colorScheme.onSurface;
    // Área central segura: 55% del diámetro deja respiración respecto
    // a los marcadores del aro y los textos verticales del fondo.
    final maxWidth = widget.size * 0.55;

    final content = switch (_mode) {
      _Mode.activeFasting => _buildActive(colorBase),
      _Mode.completedToday => _buildCompleted(colorBase),
      _Mode.eatingWindow => _buildEatingWindow(colorBase),
      _Mode.idle => _buildIdle(colorBase),
    };

    return SizedBox(
      width: maxWidth,
      child: content,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // MODOS
  // ─────────────────────────────────────────────────────────────────

  Widget _buildActive(Color colorBase) {
    final s = widget.fastingState;
    final start = s.startTime ?? _now;
    final elapsed = _now.difference(start);
    final remaining = s.timeRemainingForNextMilestone;

    return _Layout(
      label: 'AYUNO EN CURSO',
      labelColor: colorBase.withValues(alpha: 0.55),
      mainText: _fmtHms(elapsed),
      mainColor: colorBase,
      subIcon: _iconForPhase(s.phase),
      subText: remaining == Duration.zero
          ? s.metabolicMilestone
          : '${_friendlyMilestone(s.phase)} en ${_fmtHmShort(remaining)}',
      subColor: AppColors.metabolicGreen,
      size: widget.size,
    );
  }

  Widget _buildCompleted(Color colorBase) {
    final s = widget.fastingState;
    final w = widget.eatingWindow;
    final nextLabel = w != null
        ? 'Próximo: ${_fmtClock(w.windowEnd)}'
        : 'Próximo ayuno: mañana';

    return _Layout(
      label: 'AYUNO COMPLETADO',
      labelColor: colorBase.withValues(alpha: 0.55),
      mainText: '${s.targetHours}h',
      mainColor: colorBase,
      subIcon: Icons.check_circle_rounded,
      subText: nextLabel,
      subColor: AppColors.metabolicGreen,
      size: widget.size,
    );
  }

  Widget _buildEatingWindow(Color colorBase) {
    final w = widget.eatingWindow!;
    final remaining = w.windowEnd.difference(_now);
    final remainingSafe = remaining.isNegative ? Duration.zero : remaining;
    final closesAt = _fmtClock(w.windowEnd);

    return _Layout(
      label: 'PRÓXIMO AYUNO',
      labelColor: colorBase.withValues(alpha: 0.55),
      mainText: _fmtHms(remainingSafe),
      mainColor: colorBase.withValues(alpha: 0.92),
      subIcon: Icons.nightlight_round,
      subText: 'Cierra ventana $closesAt',
      subColor: colorBase.withValues(alpha: 0.65),
      size: widget.size,
    );
  }

  Widget _buildIdle(Color colorBase) {
    return _Layout(
      label: 'AYUNO',
      labelColor: colorBase.withValues(alpha: 0.55),
      mainText: '--:--:--',
      mainColor: colorBase.withValues(alpha: 0.30),
      subIcon: Icons.play_circle_outline_rounded,
      subText: 'Toca para iniciar',
      subColor: colorBase.withValues(alpha: 0.50),
      size: widget.size,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _fmtHms(Duration d) => '${_twoDigits(d.inHours)}:'
      '${_twoDigits(d.inMinutes.remainder(60))}:'
      '${_twoDigits(d.inSeconds.remainder(60))}';

  /// `3h 42m` o `42m` si menos de 1h.
  String _fmtHmShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String _fmtClock(DateTime t) =>
      '${_twoDigits(t.hour)}:${_twoDigits(t.minute)}';

  String _friendlyMilestone(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.postAbsorption:
      case FastingPhase.transition:
        return 'Quema de grasa';
      case FastingPhase.fatBurning:
        return 'Autofagia';
      case FastingPhase.autophagy:
        return 'Regeneración';
      case FastingPhase.survival:
        return 'Cierre';
      case FastingPhase.none:
        return 'Próximo hito';
    }
  }

  IconData _iconForPhase(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.postAbsorption:
        return Icons.water_drop_rounded;
      case FastingPhase.transition:
      case FastingPhase.fatBurning:
        return Icons.local_fire_department_rounded;
      case FastingPhase.autophagy:
      case FastingPhase.survival:
        return Icons.recycling_rounded;
      case FastingPhase.none:
        return Icons.bolt_rounded;
    }
  }
}

enum _Mode { activeFasting, completedToday, eatingWindow, idle }

/// Layout común a los 4 modos.
///
/// Estructura:
///   - Label superior (tipo eyebrow, pequeña, opaca, tracking amplio).
///   - Texto principal (cronómetro o número grande). Autoescala con
///     FittedBox para que nunca se desborde del área asignada.
///   - Línea inferior: icono pequeño + texto descriptivo del próximo hito.
///
/// Tipografía intencionalmente más ligera que `w900` para sentir
/// limpio y profesional, no apretado.
class _Layout extends StatelessWidget {
  final String label;
  final Color labelColor;
  final String mainText;
  final Color mainColor;
  final IconData subIcon;
  final String subText;
  final Color subColor;
  final double size;

  const _Layout({
    required this.label,
    required this.labelColor,
    required this.mainText,
    required this.mainColor,
    required this.subIcon,
    required this.subText,
    required this.subColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaños proporcionales al diámetro del reloj. Ajustados para que
    // todo el bloque quede dentro del área central segura (~55% del
    // diámetro) con respiración a cada lado.
    final labelFs = size * 0.030;
    final mainFs = size * 0.135;
    final subFs = size * 0.028;
    final iconSize = size * 0.034;
    final gapLabel = size * 0.012;
    final gapSub = size * 0.022;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            letterSpacing: 2.4,
            fontSize: labelFs,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        SizedBox(height: gapLabel),
        // FittedBox + SizedBox.width garantiza que el cronómetro se
        // escale para encajar siempre, sin importar la fuente del
        // sistema. Sin esto, "03:18:45" puede ser ligeramente más
        // ancho de lo previsto y chocar con los bordes del aro.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            mainText,
            style: TextStyle(
              color: mainColor,
              fontSize: mainFs,
              height: 1.0,
              fontWeight: FontWeight.w700,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(height: gapSub),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(subIcon, color: subColor, size: iconSize),
            SizedBox(width: size * 0.010),
            Flexible(
              child: Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subColor,
                  fontSize: subFs,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
