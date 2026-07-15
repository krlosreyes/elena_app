import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/celebration_providers.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-220: Banner de celebración al cruzar umbral 3/5 pilares
// ─────────────────────────────────────────────────────────────────────────────
//
// Widget overlay que observa `celebrationEventProvider`. Cuando recibe un
// evento, muestra un banner animado desde arriba que se auto-descarta a los
// 3 segundos. Tap descarta inmediato. One-shot: limpia el evento al consumir.
//
// Uso: insertar como hijo de un Stack en el dashboard:
//   Stack(children: [
//     ... contenido normal ...,
//     const CelebrationOverlay(),
//   ])

class CelebrationOverlay extends ConsumerStatefulWidget {
  const CelebrationOverlay({super.key});

  @override
  ConsumerState<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends ConsumerState<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  CelebrationEvent? _currentEvent;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show(CelebrationEvent event) {
    _currentEvent = event;
    // SPEC-255: el mensaje de reencuadre (streakBroken) es más largo y más
    // importante de leer con calma que un banner de "3/5 pilares" — le
    // damos más tiempo antes de auto-descartar.
    final visibleDuration = event.type == CelebrationType.streakBroken
        ? const Duration(seconds: 6)
        : const Duration(seconds: 3);
    _controller.forward().then((_) {
      Future.delayed(visibleDuration, () {
        if (mounted && _currentEvent == event) _dismiss();
      });
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() => _currentEvent = null);
        // Limpiar el provider para que no se re-dispare
        ref.read(celebrationEventProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CelebrationEvent?>(celebrationEventProvider, (prev, next) {
      if (next != null && next != prev) _show(next);
    });

    if (_currentEvent == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: _CelebrationBanner(event: _currentEvent!),
          ),
        ),
      ),
    );
  }
}

class _CelebrationBanner extends StatelessWidget {
  final CelebrationEvent event;
  const _CelebrationBanner({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _backgroundColor.withValues(alpha: 0.3), // SPEC-237 BUG-E
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85), // SPEC-237 BUG-E
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _icon {
    switch (event.type) {
      case CelebrationType.streakMilestone:
        return '🏆';
      case CelebrationType.streakBroken:
        return '🌱';
      case CelebrationType.streakThreshold:
        if (event.pillarsCompleted >= 5) return '⭐';
        if (event.pillarsCompleted >= 4) return '💪';
        if (event.currentStreak > 1) return '🔥';
        return '🎯';
    }
  }

  String get _title {
    switch (event.type) {
      case CelebrationType.streakMilestone:
        return 'Día ${event.currentStreak} de racha';
      case CelebrationType.streakBroken:
        return 'Tu racha se pausó';
      case CelebrationType.streakThreshold:
        final p = event.pillarsCompleted;
        return '$p/5 pilares';
    }
  }

  String get _subtitle {
    switch (event.type) {
      case CelebrationType.streakMilestone:
        // SPEC-255: nombrar el hito sin insinuar automaticidad (Lally 2010:
        // el promedio real para que un hábito se vuelva automático es 66
        // días, no 21 — evitamos prometer algo que no es cierto).
        return _milestoneSubtitle(event.currentStreak);
      case CelebrationType.streakBroken:
        // SPEC-255 RF-03: reencuadre autocompasivo, no de culpa. La racha
        // más larga queda como logro permanente — se lo recordamos aquí.
        //
        // P3 (2026-07-15): cuando se identificó el día y motivo exactos
        // de la ruptura, lo explicitamos — antes el mensaje era genérico
        // y no decía QUÉ faltó, dejando al usuario sin el aprendizaje.
        final reason = event.breakReason;
        final day = event.breakDayLabel;
        if (reason != null && day != null) {
          final cause = reason.isAnchorIssue
              ? 'sin ayuno ni sueño — los que más cuentan para la racha'
              : (reason.missingPillarsCount == 1
                  ? 'con 1 pilar menos del mínimo de 3'
                  : 'con ${reason.missingPillarsCount} pilares menos del mínimo de 3');
          return 'Fueron ${event.currentStreak} días reales — $day quedaste $cause. '
              'Tu récord sigue en pie. Hoy es un buen día para empezar de nuevo.';
        }
        return 'Fueron ${event.currentStreak} días reales. Tu récord sigue en pie. Hoy es un buen día para empezar de nuevo.';
      case CelebrationType.streakThreshold:
        if (event.pillarsCompleted >= 5) {
          return 'Día perfecto. Tu cuerpo lo nota.';
        }
        if (event.pillarsCompleted == 4) {
          return 'Casi perfecto. Vas muy bien.';
        }
        if (event.currentStreak > 1) {
          return 'Día ${event.currentStreak} consecutivo. Sigue así.';
        }
        return '¡Hoy cuentas para tu racha!';
    }
  }

  static String _milestoneSubtitle(int days) {
    if (days >= 100) return '100 días. Esto ya es parte de quién eres.';
    if (days >= 60) return '60 días de consistencia real.';
    if (days >= 30) return 'Un mes entero cuidándote. Se nota.';
    if (days >= 14) return 'Dos semanas seguidas. Vas construyendo el hábito.';
    if (days >= 7) return 'Una semana completa. Sigue así.';
    return 'Primeros días — la base de todo lo que viene.';
  }

  Color get _backgroundColor {
    switch (event.type) {
      case CelebrationType.streakMilestone:
        return const Color(0xFFF59E0B); // ámbar/dorado — hito
      case CelebrationType.streakBroken:
        return const Color(0xFF64748B); // slate — calma, no alarma
      case CelebrationType.streakThreshold:
        if (event.pillarsCompleted >= 5) return const Color(0xFF10B981);
        if (event.pillarsCompleted >= 4) return const Color(0xFF818CF8);
        return AppColors.metabolicGreen;
    }
  }
}
