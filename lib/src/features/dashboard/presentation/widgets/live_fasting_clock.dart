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
// Si el ayuno no está activo, el widget renderiza un placeholder estático
// y NO consume el ticker de 1s — sin overhead.

import 'dart:async';

import 'package:flutter/material.dart';

class LiveFastingClock extends StatefulWidget {
  const LiveFastingClock({
    super.key,
    required this.startTime,
    required this.isActive,
    required this.color,
    this.placeholder = '— — : — — : — —',
    this.fontSize = 28,
  });

  /// Instante de inicio del ayuno en curso. Si `isActive` es false, se ignora.
  final DateTime? startTime;

  /// True si hay un ayuno en curso. Cuando es false, el widget muestra el
  /// `placeholder` y no inicia el ticker (ahorra ciclos).
  final bool isActive;

  /// Color del display.
  final Color color;

  /// Texto a mostrar cuando `isActive` es false.
  final String placeholder;

  /// Tamaño de fuente del display.
  final double fontSize;

  @override
  State<LiveFastingClock> createState() => _LiveFastingClockState();
}

class _LiveFastingClockState extends State<LiveFastingClock> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncFromProps();
    if (widget.isActive) _startTicker();
  }

  @override
  void didUpdateWidget(covariant LiveFastingClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final activeChanged = oldWidget.isActive != widget.isActive;
    final startChanged = oldWidget.startTime != widget.startTime;
    if (activeChanged || startChanged) {
      _syncFromProps();
      if (widget.isActive) {
        _startTicker();
      } else {
        _stopTicker();
      }
    }
  }

  void _syncFromProps() {
    if (widget.isActive && widget.startTime != null) {
      _elapsed = DateTime.now().difference(widget.startTime!);
      if (_elapsed.isNegative) _elapsed = Duration.zero;
    } else {
      _elapsed = Duration.zero;
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !widget.isActive || widget.startTime == null) return;
      setState(() {
        _elapsed = DateTime.now().difference(widget.startTime!);
        if (_elapsed.isNegative) _elapsed = Duration.zero;
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

  String get _displayText {
    if (!widget.isActive || widget.startTime == null) return widget.placeholder;
    return '${_twoDigits(_elapsed.inHours)}:'
        '${_twoDigits(_elapsed.inMinutes.remainder(60))}:'
        '${_twoDigits(_elapsed.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: TextStyle(
        color: widget.color,
        fontFamily: 'monospace',
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}
