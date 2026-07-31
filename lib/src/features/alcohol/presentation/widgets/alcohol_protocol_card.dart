// SPEC-261: card de entrada al Protocolo de Consumo Consciente.
//
// Mismo patrón "widget autocontenido" que GlucoseEntryCard: ConsumerWidget
// con su propia regla de "oculto si no aplica", InkWell → context.push.
//
// Regla de visibilidad (reducción de daño, sin nagging):
//   - Si la sesión está activa → siempre visible (acompañamiento en curso).
//   - Si no, solo en franja social (tarde-noche) como invitación suave.
// Nunca moraliza ni presiona; el protocolo es opt-in.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_trigger_evaluator.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';

class AlcoholProtocolCard extends ConsumerWidget {
  const AlcoholProtocolCard({super.key});

  // Vino/ámbar: categoría social, distinta de los 5 pilares.
  static const _color = Color(0xFFB4654A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(consumptionProvider);
    final weekend = ConsumptionTriggerEvaluator.isWeekendWindow(DateTime.now());

    // Fuera de la ventana de fin de semana y sin sesión activa → no se
    // insinúa. Entre semana el usuario la activa a mano desde Perfil.
    if (!session.isActive && !weekend) return const SizedBox.shrink();

    final String title;
    final String subtitle;
    if (session.isActive) {
      title = 'Protocolo de consumo activo';
      final unidades = session.totalStandardUnits;
      final presupuesto = session.budgetStandardUnits;
      subtitle =
          '${unidades.toStringAsFixed(1)} de ${presupuesto.toStringAsFixed(1)} '
          'UEA · ${_phaseLabel(session.phase)}';
    } else {
      title = '¿Se viene plan hoy?';
      subtitle = 'Actívalo y disfruta con el mínimo costo metabólico';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/protocolo-alcohol'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wine_bar, color: _color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _phaseLabel(ConsumptionPhase phase) => switch (phase) {
        ConsumptionPhase.inactive => 'Inactivo',
        ConsumptionPhase.antes => 'Antes',
        ConsumptionPhase.durante => 'Durante',
        ConsumptionPhase.despues => 'Después',
        ConsumptionPhase.recuperacion => 'Recuperación',
      };
}
