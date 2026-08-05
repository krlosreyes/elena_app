// SPEC-264: "buzz" in-app al recibir una interacción (estilo MSN Messenger).
//
// Sin backend: mientras la app esté abierta, un zumbido llega con VIBRACIÓN
// háptica + un overlay que TIEMBLA con el emoji grande y el mensaje, en vez de
// un SnackBar discreto. (Para despertar la app cerrada haría falta push/FCM —
// ver fase 2 en SPEC-264.)

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/challenges/domain/nudge.dart';

const Color _accent = AppColors.accent;

/// Dispara el buzz: háptica repetida + overlay animado auto-descartable.
Future<void> showNudgeBuzz(
  BuildContext context, {
  required NudgeKind kind,
  required String fromName,
}) async {
  // Vibración tipo "zumbido": varios golpes cortos.
  unawaited(_buzzHaptics());
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'zumbido',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) =>
        _BuzzOverlay(kind: kind, fromName: fromName),
  );
}

Future<void> _buzzHaptics() async {
  for (var i = 0; i < 3; i++) {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 130));
  }
}

class _BuzzOverlay extends StatefulWidget {
  const _BuzzOverlay({required this.kind, required this.fromName});
  final NudgeKind kind;
  final String fromName;

  @override
  State<_BuzzOverlay> createState() => _BuzzOverlayState();
}

class _BuzzOverlayState extends State<_BuzzOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    // Auto-descartar tras unos segundos si no lo cierran.
    _autoClose = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            // Oscilación horizontal amortiguada (temblor): 3 idas y vueltas
            // que se apagan hacia el final de la animación.
            final t = _shake.value;
            final dx = (1 - t) * 14 * math.sin(t * 3 * 2 * math.pi);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _accent.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.kind.emoji,
                      style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    widget.kind.messageFrom(widget.fromName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('¡Vamos!',
                        style: TextStyle(
                            color: _accent, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
