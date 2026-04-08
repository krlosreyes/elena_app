import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/tour_controller.dart';

class SpotlightOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final Map<int, GlobalKey> stepKeys;

  const SpotlightOverlay({
    super.key,
    required this.child,
    required this.stepKeys,
  });

  @override
  ConsumerState<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends ConsumerState<SpotlightOverlay> {
  @override
  Widget build(BuildContext context) {
    final tourState = ref.watch(tourControllerProvider);
    final bool isActive = tourState.status == TourStatus.active;

    if (!isActive) return widget.child;

    return Stack(
      children: [
        widget.child,
        _buildSpotlight(tourState.currentStep),
        _buildTooltip(tourState.currentStep),
      ],
    );
  }

  Widget _buildSpotlight(int step) {
    final key = widget.stepKeys[step];
    if (key == null) {
      return Container(color: Colors.black.withValues(alpha: 0.7));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final RenderBox? renderBox =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          return Container(color: Colors.black.withValues(alpha: 0.7));
        }

        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: offset.dx - 10,
                top: offset.dy - 10,
                child: Container(
                  width: size.width + 20,
                  height: size.height + 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(int step) {
    final definitions = _getStepDefinitions(step);
    final key = widget.stepKeys[step];

    // 🧠 LÓGICA DE POSICIONAMIENTO DINÁMICO:
    // Evitamos cubrir el elemento resaltado alternando entre la parte superior e inferior.
    Alignment alignment = Alignment.center;
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 40, vertical: 80);

    if (key != null && key.currentContext != null) {
      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final centerY = offset.dy + (renderBox.size.height / 2);

        // Si el elemento está en la mitad superior, mostramos el tooltip abajo y viceversa
        if (centerY < screenHeight * 0.5) {
          alignment = Alignment.bottomCenter;
        } else {
          alignment = Alignment.topCenter;
        }
      }
    }

    return AnimatedAlign(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      alignment: alignment,
      child: Padding(
        padding: padding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border.all(
                    color: _getStepPillarColor(step).withValues(alpha: 0.8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _getStepPillarColor(step).withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStepPillarColor(step),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          definitions['title']!,
                          style: GoogleFonts.jetBrainsMono(
                            color: _getStepPillarColor(step),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          definitions['content']!,
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(tourControllerProvider.notifier)
                                  .nextStep();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getStepPillarColor(step),
                              foregroundColor: Colors.black,
                              shape: const BeveledRectangleBorder(),
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: Text(
                              step == 5
                                  ? 'FINALIZAR SISTEMA'
                                  : 'SIGUIENTE MÓDULO',
                              style: GoogleFonts.jetBrainsMono(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStepPillarColor(int step) {
    switch (step) {
      case 0:
        return const Color(0xFF51C878); // Welcome
      case 1:
        return const Color(0xFFFFD600); // Hub
      case 2:
        return const Color(0xFFFFD600); // Nutrition
      case 3:
        return const Color(0xFFE94560); // Pause
      case 4:
        return const Color(0xFF51C878); // Analysis
      case 5:
        return const Color(0xFFE94560); // Panic
      default:
        return Colors.white;
    }
  }

  Map<String, String> _getStepDefinitions(int step) {
    switch (step) {
      case 0:
        return {
          'title': 'BIENVENIDO A ELENA',
          'content':
              'Soy tu asistente de optimización metabólica. Iniciemos un breve recorrido técnico por tu nuevo tablero de control.',
        };
      case 1:
        return {
          'title': 'NÚCLEO IMR',
          'content':
              'Este es tu Índice de Metamorfosis Real. Centraliza datos de hidratación, nutrición, sueño y ejercicio en tiempo real.',
        };
      case 2:
        return {
          'title': 'VENTANA METABÓLICA',
          'content':
              'Aquí visualizas si tu ventana de alimentación está abierta o cerrada. El ritmo circadiano es la base de tu longevidad.',
        };
      case 3:
        return {
          'title': 'PAUSA TÉCNICA',
          'content':
              'Para optimizar el motor, necesitamos conocer tus preferencias. Vamos a configurar tu perfil nutricional ahora.',
        };
      case 4:
        return {
          'title': 'PILARES OPERATIVOS',
          'content':
              'Cada segmento monitorea un pilar. Hidratación, Sueño, Nutrición y Ejercicio alimentan tu puntaje IMR.',
        };
      case 5:
        return {
          'title': 'PROTOCOLO DE EMERGENCIA',
          'content':
              '¿Hambre fuera de horario? Usa el Pánico de Hambre para recibir una diagnosis inmediata y evitar el catabolismo.',
        };
      default:
        return {'title': '', 'content': ''};
    }
  }
}
