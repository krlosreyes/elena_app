// SPEC-261.4: acceso al Protocolo de Consumo Consciente desde el header del
// Dashboard (entre "Hoy" y la foto de perfil). Ícono de copa/coctel que
// comunica fiesta/tragos. Punto de acento cuando estamos en la ventana de fin
// de semana o hay una sesión activa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_trigger_evaluator.dart';

class AlcoholHeaderButton extends ConsumerWidget {
  const AlcoholHeaderButton({super.key});

  static const _accent = Color(0xFFB4654A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(consumptionProvider.select((s) => s.isActive));
    final weekend = ConsumptionTriggerEvaluator.isWeekendWindow(DateTime.now());
    final highlight = active || weekend;

    return InkWell(
      onTap: () => context.push('/protocolo-alcohol'),
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: highlight ? 0.20 : 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_bar, color: _accent, size: 22),
            ),
            if (highlight)
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.backgroundDark, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
