// SPEC-101: diálogo de confirmación cuando el usuario quiere terminar
// el ayuno antes de completar el 100% del protocolo.
//
// Diseño: AlertDialog Material 3 con sección de beneficios obtenidos
// (FastingBenefits.benefitsFor) para que el usuario decida con
// información, no impulso. No bloquea — solo educa.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_benefits.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';

class EarlyFastingEndDialog extends StatelessWidget {
  final Duration elapsed;
  final int targetHours;
  final FastingPhase phase;

  const EarlyFastingEndDialog({
    super.key,
    required this.elapsed,
    required this.targetHours,
    required this.phase,
  });

  /// Muestra el diálogo y resuelve con `true` si el usuario confirma
  /// terminar el ayuno, `false` o `null` si cancela / cierra.
  static Future<bool?> show(
    BuildContext context, {
    required Duration elapsed,
    required int targetHours,
    required FastingPhase phase,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EarlyFastingEndDialog(
        elapsed: elapsed,
        targetHours: targetHours,
        phase: phase,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benefits = FastingBenefits.benefitsFor(phase, elapsed);
    final milestone = FastingBenefits.milestoneLabel(phase);

    final int hours = elapsed.inHours;
    final int minutes = elapsed.inMinutes % 60;
    final String elapsedLabel =
        hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';
    final int progressPct =
        ((elapsed.inSeconds / (targetHours * 3600)) * 100)
            .clamp(0, 100)
            .round();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        '¿Terminar el ayuno?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progreso actual.
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Llevas $elapsedLabel de ${targetHours}h '
                      '($progressPct% completado)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estado actual: $milestone',
              style: const TextStyle(
                color: AppColors.metabolicGreen,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Beneficios obtenidos hasta ahora:',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            ...benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.metabolicGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.30),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si terminas ahora, este ayuno NO contará como '
                      'completado. Podrás iniciar otro hoy.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text(
            'Continuar ayuno',
            style: TextStyle(
              color: AppColors.metabolicGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Sí, terminar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
