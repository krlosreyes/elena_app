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
import 'package:elena_app/src/features/exercise/presentation/widgets/rest_day_prompt_sheet.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';
import 'package:elena_app/src/features/onboarding/application/tour_targets_provider.dart';
import 'package:elena_app/src/router/app_router.dart' show rootNavigatorKey;

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

  /// Referencia al ScrollController del dashboard para hacer scroll
  /// automático y para escuchar cambios que rebuilden el spotlight.
  ScrollController? _scrollCtrl;

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

    // Suscribirse al ScrollController del dashboard en el primer frame
    // (el provider ya existe pero el controller puede no tener clients aún).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollCtrl = ref.read(dashboardScrollControllerProvider);
      _scrollCtrl?.addListener(_onScroll);
    });
  }

  /// Rebuild el overlay en cada tick de scroll para que `localToGlobal()`
  /// devuelva la posición actualizada y el spotlight siga al Row.
  void _onScroll() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollCtrl?.removeListener(_onScroll);
    _anim.dispose();
    super.dispose();
  }

  static bool _isPilarStep(TourSpotlightArea area) {
    switch (area) {
      case TourSpotlightArea.fastingRing:
      case TourSpotlightArea.sleepRing:
      case TourSpotlightArea.hydrationRing:
      case TourSpotlightArea.exerciseRing:
      case TourSpotlightArea.comidasRing:
        return true;
      default:
        return false;
    }
  }

  /// Anima el scroll del dashboard para que el centro del Row de PillarRings
  /// quede al ~68 % de la altura útil (por encima del tab bar).
  void _scrollToShowPilars(Size screenSize, double safeBottom) {
    final ctrl = _scrollCtrl;
    if (ctrl == null || !ctrl.hasClients) return;

    final rowKey = ref.read(pillarRowKeyProvider);
    final rb = rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) return;

    const tabBarH = 56.0;
    final usableH = screenSize.height - tabBarH - safeBottom;
    // Queremos que la MITAD del Row de anillos caiga al 68 % del área útil.
    final targetCenterY = usableH * 0.68;

    final rowOffset = rb.localToGlobal(Offset.zero);
    final rowCenterY = rowOffset.dy + rb.size.height / 2;
    final delta = rowCenterY - targetCenterY;

    if (delta.abs() < 24) return; // ya está en buen lugar, no mover

    final targetOffset =
        (ctrl.offset + delta).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  /// Anima el scroll para que el DualScoreRing quede al ~30% del área útil.
  /// Se llama al entrar en el paso scoreCard, que llega después de los pasos
  /// de pilar (los cuales dejaron el scroll en una posición más baja).
  void _scrollToShowScore(Size screenSize, double safeBottom) {
    final ctrl = _scrollCtrl;
    if (ctrl == null || !ctrl.hasClients) return;

    final scoreKey = ref.read(dualScoreRingKeyProvider);
    final rb = scoreKey.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) {
      // Fallback: volver al inicio.
      ctrl.animateTo(
        0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
      return;
    }

    const tabBarH = 56.0;
    final usableH = screenSize.height - tabBarH - safeBottom;
    // Queremos que el CENTRO del DualScoreRing quede al 32% del área útil.
    final targetCenterY = usableH * 0.32;

    final offset = rb.localToGlobal(Offset.zero);
    final centerY = offset.dy + rb.size.height / 2;
    final delta = centerY - targetCenterY;

    if (delta.abs() < 24) return;

    final targetOffset =
        (ctrl.offset + delta).clamp(0.0, ctrl.position.maxScrollExtent);
    ctrl.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleNavigation(TourStep step) async {
    if (step.navigateTo == null) return;
    // El overlay vive en el builder de MaterialApp, ENCIMA del Router.
    // El context local no tiene InheritedGoRouter → context.go() lanzaba
    // "No GoRouter found in context". Usamos rootNavigatorKey que SÍ vive
    // dentro del árbol del Router (registrado en app_router.dart).
    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx != null && navCtx.mounted) {
      navCtx.go(step.navigateTo!);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _advance(
      AppTourNotifier notifier, AppTourState tourState) async {
    // Propuesta (22-jul): capturado ANTES de avanzar — `nextStep()` en el
    // último paso dispara `_finish()` y deja `isActive=false`, así que
    // `tourState.isLastStep` ya no se podría leer después con el mismo
    // significado. Se guarda acá para decidir si mostramos el prompt de
    // día de descanso una vez que el tour realmente termina.
    final wasLastStep = tourState.isLastStep;
    final next = tourState.stepIndex + 1;
    if (next < kTourSteps.length) {
      await _handleNavigation(kTourSteps[next]);
    }
    await notifier.nextStep();

    // Propuesta (22-jul, líder de proyecto): al terminar el tour tocando
    // "¡Empezar!" (NO al "Saltar" — eso pasa por `onSkip`, nunca por acá),
    // ofrecemos elegir el día de descanso preferido para el plan de
    // ejercicio semanal. Ver rest_day_prompt_sheet.dart para el porqué y
    // por qué esto no necesita un flag propio de "ya se mostró": el tour
    // mismo ya solo corre una vez por cuenta (app_tour_notifier.dart).
    if (wasLastStep) {
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx != null && navCtx.mounted) {
        await showRestDayPromptSheet(navCtx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(appTourProvider);

    if (!tourState.isActive) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Animar entrada cuando el paso cambia.
    if (tourState.stepIndex != _lastStep) {
      _lastStep = tourState.stepIndex;
      _anim.forward(from: 0);
      final spotlight = tourState.currentStep.spotlight;
      // Scroll automático según el tipo de paso.
      if (_isPilarStep(spotlight)) {
        // Pilares: bajar para mostrar anillos al 68% del área útil.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToShowPilars(size, safeBottom);
        });
      } else if (spotlight == TourSpotlightArea.scoreCard) {
        // Progreso Hoy: subir para que el DualScoreRing quede al ~30% del área útil.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToShowScore(size, safeBottom);
        });
      }
    }

    final step = tourState.currentStep;
    final notifier = ref.read(appTourProvider.notifier);
    final pillarRowKey = ref.read(pillarRowKeyProvider);
    final dualScoreKey = ref.read(dualScoreRingKeyProvider);

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
              pillarRowKey: pillarRowKey,
              dualScoreRingKey: dualScoreKey,
              bottomSafeArea: safeBottom,
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
                  onNext: () => _advance(notifier, tourState),
                  onSkip: () async {
                    rootNavigatorKey.currentContext?.go('/dashboard');
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
  final GlobalKey? pillarRowKey;

  /// GlobalKey del DualScoreRing para medir posición real del scoreCard.
  final GlobalKey? dualScoreRingKey;

  /// Altura del safe area inferior (home indicator) obtenida de MediaQuery.
  /// Se usa para calcular el límite inferior real del spotlight sin invadir
  /// el tab bar ni el home indicator.
  final double bottomSafeArea;

  const _SpotlightOverlay({
    super.key,
    required this.area,
    required this.screenSize,
    this.pillarRowKey,
    this.dualScoreRingKey,
    this.bottomSafeArea = 34.0,
  });

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
        // El reloj CircadianClock ocupa ~78% del ancho de pantalla con ratio 1:1.
        // Basado en screenshots reales: aparece aproximadamente entre h*0.18–0.55.
        holeRect = Rect.fromLTWH(
          w * 0.07,
          h * 0.18,
          w * 0.86,
          h * 0.38,
        );
        break;

      case TourSpotlightArea.pillarRow:
        // Fila de los 5 anillos en la parte baja de la card PROGRESO HOY.
        holeRect = Rect.fromLTWH(0, h * 0.79, w, h * 0.13);
        break;

      // Columnas individuales de cada pilar.
      // SPEC-243 fix: usa pillarRowKey para medir posición real del Row
      // (independiente de cuántas cards condicionales estén encima).
      // Si el key aún no tiene context (primer frame), cae al fallback h*0.57.
      case TourSpotlightArea.fastingRing:
        holeRect = _ringColumn(0, w, h, pillarRowKey);
        break;
      case TourSpotlightArea.sleepRing:
        holeRect = _ringColumn(1, w, h, pillarRowKey);
        break;
      case TourSpotlightArea.hydrationRing:
        holeRect = _ringColumn(2, w, h, pillarRowKey);
        break;
      case TourSpotlightArea.exerciseRing:
        holeRect = _ringColumn(3, w, h, pillarRowKey);
        break;
      case TourSpotlightArea.comidasRing:
        holeRect = _ringColumn(4, w, h, pillarRowKey);
        break;

      case TourSpotlightArea.scoreCard:
        // SPEC-243 fix: usa dualScoreRingKey para medir posición real.
        // El scoreCard llega DESPUÉS de los pasos de pilar, que hacen scroll.
        // Las coordenadas hardcoded anteriores (h*0.59) apuntaban al scroll=0
        // y quedaban desfasadas. Ahora: localToGlobal() da la posición real
        // independientemente del offset de scroll.
        // El spotlight cubre: 50pt sobre el DualScoreRing (título PROGRESO HOY)
        // + el ring + 40pt abajo (frase motivacional).
        if (dualScoreRingKey?.currentContext != null) {
          final rb = dualScoreRingKey!.currentContext!.findRenderObject()
              as RenderBox?;
          if (rb != null && rb.hasSize) {
            final offset = rb.localToGlobal(Offset.zero);
            const titlePad = 50.0; // espacio para el título "PROGRESO HOY"
            const motivPad = 40.0; // espacio para la frase motivacional
            holeRect = Rect.fromLTWH(
              w * 0.04,
              offset.dy - titlePad,
              w * 0.92,
              rb.size.height + titlePad + motivPad,
            );
          }
        }
        // Fallback si el key no tiene context todavía.
        holeRect ??= Rect.fromLTWH(w * 0.04, h * 0.55, w * 0.92, h * 0.22);
        break;

      case TourSpotlightArea.fullScreen:
        // Pantalla completa visible — solo una sombra muy ligera en los bordes.
        holeRect = Rect.fromLTWH(0, 0, w, h);
        break;
    }

    // Límite inferior del spotlight: justo encima del tab bar.
    // Tab bar Flutter estándar = 56 pt. Safe area inferior = bottomSafeArea.
    // Dejamos 4 pt de margen extra para no rozar el borde.
    final bottomLimit = screenSize.height - 56.0 - bottomSafeArea - 4.0;

    return CustomPaint(
      painter: _SpotlightPainter(holeRect: holeRect, bottomLimit: bottomLimit),
      child: const SizedBox.expand(),
    );
  }

  /// Columna estrecha que ilumina el slot de un pilar dentro del Row de anillos.
  ///
  /// SPEC-243 fix v2: usa [pillarRowKey] para obtener X, Y, ancho y alto reales
  /// del Row mediante localToGlobal() + renderBox.size. Esto corrige dos bugs:
  ///   1. Y independiente de cuántas cards condicionales estén encima.
  ///   2. X calculada a partir del offset real del Row (que empieza en x=42pt
  ///      por el padding del card exterior 24+18), no del scrollPad hardcoded
  ///      que sólo consideraba el padding del SingleChildScrollView (24pt) y
  ///      producía ≈14pt de desfase en Ayuno/Comidas.
  ///
  /// Fallback si el key no tiene context todavía: coordenadas aproximadas
  /// (h*0.57, rowWidth calculado con scrollPad=42).
  static Rect _ringColumn(int index, double w, double h, GlobalKey? rowKey) {
    // ── Posición y dimensiones reales desde el GlobalKey ───────────────────
    double rowTop = h * 0.57; // fallback Y
    double rowHeight = h * 0.13; // fallback alto
    double rowLeft = 42.0; // fallback X: scrollPad(24)+cardPad(18)
    double rowWidth = w - 2 * 42.0; // fallback ancho

    if (rowKey?.currentContext != null) {
      final renderBox =
          rowKey!.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final offset = renderBox.localToGlobal(Offset.zero);
        rowTop = offset.dy;
        rowHeight = renderBox.size.height;
        rowLeft = offset.dx;
        rowWidth = renderBox.size.width;
      }
    }

    // ── X calculada con aritmética spaceAround sobre el ancho REAL del Row ─
    const ringSize = 56.0;
    const n = 5;
    // spaceAround: espacio a cada lado de un ring = (rowWidth - n*ringSize)/(n*2)
    final halfGap = (rowWidth - n * ringSize) / (n * 2.0);
    // Centro X del anillo `index` en coordenadas de pantalla.
    final cx =
        rowLeft + halfGap + index * (ringSize + 2.0 * halfGap) + ringSize / 2.0;

    // Padding lateral ampliado (16pt) para dar más presencia visual al spotlight
    // y que el anillo quede bien enmarcado, no justo en el borde.
    const colPadH = 16.0;
    final left = (cx - ringSize / 2.0 - colPadH).clamp(0.0, w);
    final colW = (ringSize + 2.0 * colPadH).clamp(0.0, w - left);

    const vPad = 8.0;
    return Rect.fromLTWH(left, rowTop - vPad, colW, rowHeight + vPad * 2);
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? holeRect;

  /// Coordenada Y máxima permitida para el borde inferior del spotlight.
  /// Calculada como screenHeight - tabBarH - safeBottom - 4.
  /// Si es null, cae al fallback h*0.90 (comportamiento previo).
  final double? bottomLimit;

  const _SpotlightPainter({this.holeRect, this.bottomLimit});

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

    // Recortar el hueco para que nunca se extienda dentro del tab bar.
    // Antes: clamp hardcoded a h*0.90, demasiado agresivo en dispositivos
    // con safe area grande. Ahora: límite calculado como
    // screenH - tabBarH(56) - safeBottom - 4pt.
    final limit = bottomLimit ?? size.height * 0.90;
    final effectiveHole = Rect.fromLTRB(
      holeRect!.left,
      holeRect!.top,
      holeRect!.right,
      holeRect!.bottom.clamp(0.0, limit),
    );

    // PathFillType.evenOdd hace que la intersección de los dos sub-paths
    // se reste → el RRect interior queda transparente (el hueco visible).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(screenRect)
      ..addRRect(
          RRect.fromRectAndRadius(effectiveHole, const Radius.circular(20)));

    canvas.drawPath(
      path,
      Paint()
        ..color = overlayColor
        ..blendMode = BlendMode.srcOver,
    );

    // Halo brillante alrededor del hueco (ya recortado).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          effectiveHole.inflate(3), const Radius.circular(22)),
      Paint()
        ..color = AppColors.metabolicGreen.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.holeRect != holeRect || old.bottomLimit != bottomLimit;
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
        return false; // pilares están abajo → card arriba
      case TourSpotlightArea.scoreCard:
        // Tras el scroll automático, el DualScoreRing queda al ~32% de la
        // pantalla (parte alta). La card debe ir abajo para no taparlo.
        return true;
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
                  Text(step.emoji, style: const TextStyle(fontSize: 28)),
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
