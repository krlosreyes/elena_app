import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class InteractiveTourService {
  final BuildContext context;
  final List<GlobalKey> stepKeys;
  final VoidCallback? onComplete;

  InteractiveTourService({
    required this.context,
    required this.stepKeys,
    this.onComplete,
  });

  void showTour() {
    final targets = _createTargets();

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.95,
      hideSkip: true,
      onClickOverlay: (target) {
        // Bloqueamos clics externos para asegurar el flujo secuencial solicitado
      },
      onFinish: onComplete,
    ).show(context: context);
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];

    final pilarNames = [
      'AYUNO METABÓLICO',
      'MOVIMIENTO ESTRATÉGICO',
      'NUTRICIÓN OPTIMIZADA',
      'HIDRATACIÓN CELULAR',
      'SUEÑO REPARADOR',
      'PANEL DE PÁNICO',
    ];

    final pilarColors = [
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.lightBlue,
      Colors.cyanAccent,
      Colors.deepPurpleAccent,
      Colors.redAccent,
    ];

    for (int i = 0; i < stepKeys.length; i++) {
      targets.add(
        TargetFocus(
          identify: "Step $i",
          keyTarget: stepKeys[i],
          shape: ShapeLightFocus.RRect,
          paddingFocus: 15,
          color: Colors.black,
          contents: [
            TargetContent(
              align: i == 5 ? ContentAlign.top : ContentAlign.bottom,
              builder: (context, controller) {
                return _buildSpeechBubble(
                  pilarNames[i],
                  _getDescription(i),
                  pilarColors[i],
                  onNext: () => controller.next(),
                );
              },
            ),
          ],
        ),
      );
    }

    return targets;
  }

  String _getDescription(int step) {
    switch (step) {
      case 0:
        return 'Controla tu ventana de quema de grasas activa.';
      case 1:
        return 'Registra tu actividad física diaria y movimiento.';
      case 2:
        return 'Configura tus fuentes de macronutrientes ahora mismo.';
      case 3:
        return 'Mantén tus niveles de hidratación celular óptimos.';
      case 4:
        return 'Monitorea la calidad de tu descanso reparador.';
      case 5:
        return 'Acceso rápido para gestionar momentos de hambre emocional.';
      default:
        return '';
    }
  }

  Widget _buildSpeechBubble(
    String title,
    String desc,
    Color accentColor, {
    required VoidCallback onNext,
    bool showButton = true,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
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
                decoration:
                    BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.publicSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (showButton) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: const BeveledRectangleBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 12,
                  shadowColor: accentColor.withValues(alpha: 0.5),
                ),
                child: Text(
                  'SIGUIENTE',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
