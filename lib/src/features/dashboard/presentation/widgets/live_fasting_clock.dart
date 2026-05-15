// SPEC-61: LiveFastingClock — display HH:MM:SS con ticker local de 1s.
//
// Antes, el FastingNotifier mutaba `fastingProvider.duration` cada segundo
// vía Timer.periodic interno. Eso disparaba rebuilds en TODA la UI suscrita
// a fastingProvider (incluido CircadianClock, anillos de pilares, indicadores
// de fase, etc.) — ~60 rebuilds por minuto sin necesidad real.
//
// Ahora el notifier solo se actualiza al pulso de 10s (metabolicPulseProvider).
// Este widget mantiene el display segundo a segundo localmente: lee
// `startTime` (que sí cambia poco) y recalcula `now.difference(startTime)`
// cada segundo en su propio State, sin tocar el notifier global.
//
// SPEC-113.feat: dos modos.
//   - Ayuno activo → cronómetro ascendente HH:MM:SS desde startTime.
//   - Ayuno inactivo + `nextFastingTime` → cuenta regresiva descendente
//     hasta el próximo ayuno (e.g., próximo cierre de ventana de
//     alimentación, calculado desde `profile.lastMealGoal`).
//   - Ayuno inactivo sin `nextFastingTime` → placeholder estático.

import 'dart:async';

import 'package:flutter/material.dart';

class LiveFastingClock extends StatefulWidget {
  const LiveFastingClock({
    super.key,
    required this.startTime,
    required this.isActive,
    required this.color,
    this.nextFastingTime,
    this.placeholder = '— — : — — : — —',
    this.fontSize = 28,
  });

  /// Instante de inicio del ayuno en curso. Si `isActive` es false, se ignora.
  final DateTime? startTime;

  /// True si hay un ayuno en curso. Cuando es false, el widget muestra el
  /// countdown a `nextFastingTime` o el `placeholder`.
  final bool isActive;

  /// SPEC-113.feat: cuándo se inicia el próximo ayuno. Solo se usa cuando
  /// `isActive` es false. Si está seteado y aún no llegó, el display
  /// muestra cuenta regresiva HH:MM:SS hasta ese instante.
  final DateTime? nextFastingTime;

  /// Color del display.
  final Color color;

  /// Texto a mostrar cuando `isActive` es false y no hay countdown válido.
  final String placeholder;

  /// Tamaño de fuente del display.
  final double fontSize;

  @override
  State<LiveFastingClock> createState() => _LiveFastingClockState();
}

class _LiveFastingClockState extends State<LiveFastingClock> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero; // duración del ayuno activo
  Duration _remaining = Duration.zero; // tiempo hasta el próximo ayuno

  bool get _isCountdownMode =>
      !widget.isActive && widget.nextFastingTime != null;

  bool get _needsTicker => widget.isActive || _isCountdownMode;

  @override
  void initState() {
    super.initState();
    _syncFromProps();
    if (_needsTicker) _startTicker();
  }

  @override
  void didUpdateWidget(covariant LiveFastingClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeChanged = oldWidget.isActive != widget.isActive;
    final startChanged = oldWidget.startTime != widget.startTime;
    final nextChanged = oldWidget.nextFastingTime != widget.nextFastingTime;
    if (activeChanged || startChanged || nextChanged) {
      _syncFromProps();
      if (_needsTicker) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }
  }

  void _syncFromProps() {
    final now = DateTime.now();
    if (widget.isActive && widget.startTime != null) {
      _elapsed = now.difference(widget.startTime!);
      if (_elapsed.isNegative) _elapsed = Duration.zero;
      _remaining = Duration.zero;
    } else if (_isCountdownMode) {
      _remaining = widget.nextFastingTime!.difference(now);
      if (_remaining.isNegative) _remaining = Duration.zero;
      _elapsed = Duration.zero;
    } else {
      _elapsed = Duration.zero;
      _remaining = Duration.zero;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        if (widget.isActive && widget.startTime != null) {
          _elapsed = now.difference(widget.startTime!);
          if (_elapsed.isNegative) _elapsed = Duration.zero;
        } else if (_isCountdownMode) {
          _remaining = widget.nextFastingTime!.difference(now);
          if (_remaining.isNegative) _remaining = Duration.zero;
        }
      });
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

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _fmt(Duration d) =>
      '${_twoDigits(d.inHours)}:'
      '${_twoDigits(d.inMinutes.remainder(60))}:'
      '${_twoDigits(d.inSeconds.remainder(60))}';

  String get _displayText {
    if (widget.isActive && widget.startTime != null) {
      return _fmt(_elapsed);
    }
    if (_isCountdownMode) {
      if (_remaining == Duration.zero) {
        // Llegamos a la hora del próximo ayuno y aún no hay intervalo
        // activo (típicamente faltan segundos de propagación). Mostramos
        // un display "listo".
        return '00:00:00';
      }
      return _fmt(_remaining);
    }
    return widget.placeholder;
  }

  @override
  Widget build(BuildContext context) {
    // En modo countdown bajamos un poco el contraste para diferenciar
    // visualmente que es "tiempo restante" y no "tiempo acumulado".
    final color = _isCountdownMode
        ? widget.color.withValues(alpha: 0.85)
        : widget.color;
    return Text(
      _displayText,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
