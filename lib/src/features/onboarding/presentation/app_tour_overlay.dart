// SPEC-243 — Overlay del tour interactivo post-onboarding.
//
// Se monta sobre todo el árbol de widgets en `app.dart` mediante un
// `Stack`. Cuando `appTourProvider.isActive` es false, retorna
// `SizedBox.shrink()` sin costo alguno.
//
// Diseño visual:
//   - Fondo oscuro (black 80%) con hueco circular/rectangular según el
//     paso: el usuario VE la UI real debajo del hueco.
//   - Tarjeta de coaching en la zona opuesta al hueco (si el hueco está
//     arriba, la card va abajo; y viceversa).
//   - Flecha SVG apunta desde la card al hueco.
//   - Contador de pasos + botones "Saltar" / "Siguiente" / "¡Empezar!".
//   - Animación de fade + slide entre pasos.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

class AppTourOverlay extends ConsumerStatefulWidget {
  const AppTourOverlay({super.key});

  @override
  ConsumerState<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends ConsumerState<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  int _lastStep = -1;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation(TourStep step, BuildContext ctx) async {
    if (step.navigateTo != null && ctx.mounted) {
      ctx.go(step.navigateTo!);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _advance(BuildContext ctx, AppTourNotifier notifier,
      AppTourState tourState) async {
    final next = tourState.stepIndex + 1;
    if (next < kTourSteps.length) {
      final nextStep = kTourSteps[next];
      await _handleNavigation(nextStep, ctx);
    }
    await notifier.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(appTourProvider);

    if (!tourState.isActive) return const SizedBox.shrink();

    // Animar entrada cuando el paso cambia.
    if (tourState.stepIndex != _lastStep) {
      _lastStep = tourState.stepIndex;
      _anim.forward(from: 0);
    }

    final step = tourState.currentStep;
    final size = MediaQuery.of(context).size;
    final notifier = ref.read(appTourProvider.notifier);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Capa de oscurecimiento con hueco ────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _SpotlightOverlay(
              key: ValueKey(step.spotlight),
              area: step.spotlight,
              screenSize: size,
            ),
          ),

          // ── Tarjeta del coach mark ───────────────────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: _CoachCard(
                  step: step,
                  stepIndex: tourState.stepIndex,
                  totalSteps: tourState.totalSteps,
                  screenSize: size,
                  onNext: () => _advance(context, notifier, tourState),
                  onSkip: () async {
                    context.go('/dashboard');
                    await notifier.skip();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spotlight: hueco en el overlay oscuro ────────────────────────────────────

class _SpotlightOverlay extends StatelessWidget {
  final TourSpotlightArea area;
  final Size screenSize;

  const _SpotlightOverlay({super.key, required this.area, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final h = screenSize.height;
    final w = screenSize.width;

    // Calcula el Rect del hueco según el área objetivo.
    Rect? holeRect;
    switch (area) {
      case TourSpotlightArea.none:
        break; // sin hueco

      case TourSpotlightArea.clock:
        // El reloj ocupa ~el 30-55% vertical de la pantalla (después del header
        // y los banners). Hueco centrado en horizontal, oval.
        holeRect = Rect.fromLTWH(
          w * 0.05,
          h * 0.22,
          w * 0.90,
          h * 0.38,
        );
        break;

      case TourSpotlightArea.pillarRow:
        // Fila completa de los 5 anillos (~72-84% vertical).
        holeRect = Rect.fromLTWH(0, h * 0.70, w, h * 0.15);
        break;

      case TourSpotlightArea.fastingRing:
        holeRect = _ringHole(0, w, h);
        break;
      case TourSpotlightArea.sleepRing:
        holeRect = _ringHole(1, w, h);
        break;
      case TourSpotlightArea.hydrationRing:
        holeRect = _ringHole(2, w, h);
        break;
      case TourSpotlightArea.exerciseRing:
        holeRect = _ringHole(3, w, h);
        break;
      case TourSpotlightArea.comidasRing:
        holeRect = _ringHole(4, w, h);
        break;

      case TourSpotlightArea.scoreCard:
        // Card PROGRESO HOY aparece debajo de los pilares (~78-95% vertical).
        holeRect = Rect.fromLTWH(
          w * 0.02,
          h * 0.65,
          w * 0.96,
          h * 0.22,
        );
        break;

      case TourSpotlightArea.fullScreen:
        // Pantalla completa visible — solo una sombra muy ligera en los bordes.
        holeRect = Rect.fromLTWH(0, 0, w, h);
        break;
    }

    return CustomPaint(
      painter: _SpotlightPainter(holeRect: holeRect),
      child: const SizedBox.expand(),
    );
  }

  /// Calcula el Rect de un anillo individual de pilar.
  /// [index] 0=Ayuno, 1=Sueño, 2=Hidratación, 3=Ejercicio, 4=Comidas.
  Rect _ringHole(int index, double w, double h) {
    // La fila de 5 anillos está espaciada uniformemente.
    // Cada columna ocupa w/5; el anillo centra en esa columna.
    const ringCount = 5;
    final colW = w / ringCount;
    final cx = colW * index + colW / 2;
    const ringRadius = 32.0;
    const ringTop = 0.71; // fracción vertical de inicio de la fila

    return Rect.fromCenter(
      center: Offset(cx, h * ringTop + ringRadius + 8),
      width: ringRadius * 2 + 20,
      height: ringRadius * 2 + 48, // incluye el label debajo
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? holeRect;

  const _SpotlightPainter({this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayColor = Colors.black.withValues(alpha: 0.82);
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (holeRect == null) {
      // Sin hueco — oscurece todo.
      canvas.drawRect(screenRect, Paint()..color = overlayColor);
      return;
    }

    if (holeRect == Rect.fromLTWH(0, 0, size.width, size.height)) {
      // fullScreen — sombra muy ligera.
      canvas.drawRect(
          screenRect, Paint()..color = Colors.black.withValues(alpha: 0.35));
      return;
    }

    // PathFillType.evenOdd hace que la intersección de los dos sub-paths
    // se reste → el RRect interior queda transparente (el hueco visible).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screenRect)
      ..addRRect(RRect.fromRectAndRadius(holeRect!, const Radius.circular(20)));

    canvas.drawPath(
      path,
      Paint()
        ..color = overlayColor
        ..blendMode = BlendMode.srcOver,
    );

    // Halo brillante alrededor del hueco.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          holeRect!.inflate(3), const Radius.circular(22)),
      Paint()
        ..color = AppColors.metabolicGreen.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.holeRect != holeRect;
}

// ── Tarjeta del coach mark ────────────────────────────────────────────────────

class _CoachCard extends StatelessWidget {
  final TourStep step;
  final int stepIndex;
  final int totalSteps;
  final Size screenSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _CoachCard({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.screenSize,
    required this.onNext,
    required this.onSkip,
  });

  /// ¿La card va en la mitad inferior? (cuando el spotlight ocupa la parte
  /// alta de la pantalla, la card va abajo, y viceversa).
  bool get _cardAtBottom {
    switch (step.spotlight) {
      case TourSpotlightArea.none:
      case TourSpotlightArea.fullScreen:
        return true;
      case TourSpotlightArea.clock:
        return true; // clock está arriba → card abajo
      case TourSpotlightArea.fastingRing:
      case TourSpotlightArea.sleepRing:
      case TourSpotlightArea.hydrationRing:
      case TourSpotlightArea.exerciseRing:
      case TourSpotlightArea.comidasRing:
      case TourSpotlightArea.pillarRow:
      case TourSpotlightArea.scoreCard:
        return false; // pilares/score están abajo → card arriba
    }
  }

  bool get _isLast => stepIndex == totalSteps - 1;

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment:
            _cardAtBottom ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_cardAtBottom) ...[
            const Spacer(),
            card,
            SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ] else ...[
            SizedBox(height: MediaQuery.of(context).padding.top + 12),
            card,
            const Spacer(),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.metabolicGreen.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contador de pasos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepDots(current: stepIndex, total: totalSteps),
                  if (!_isLast)
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        'Saltar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.40),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Emoji + título
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(step.emoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cuerpo
              Text(
                step.body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // CTA principal
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.metabolicGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isLast ? '¡Empezar!' : 'Siguiente →',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dots de progreso ──────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  final int current;
  final int total;

  const _StepDots({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 5),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.metabolicGreen
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
