// SPEC-261.3: card de entrada permanente al Protocolo de Consumo Consciente
// en Perfil > Configuración. Mismo patrón que ProtocoloEntryCard.
//
// Existe para que el usuario pueda activar el protocolo CUANDO QUIERA
// —también entre semana si tiene un evento—, sin depender de la ventana
// automática de fin de semana que usa la card del dashboard.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';

class AlcoholProtocolEntryCard extends ConsumerWidget {
  const AlcoholProtocolEntryCard({super.key});

  static const _color = Color(0xFFB4654A); // vino/ámbar

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(consumptionProvider);
    final subtitle = session.isActive
        ? 'Activo · ${session.totalStandardUnits.toStringAsFixed(1)} UEA'
        : 'Actívalo para tus salidas y eventos';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/protocolo-alcohol'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
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
                  const Text(
                    'Consumo consciente',
                    style: TextStyle(
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
    );
  }
}
