// Módulo "Tu Glucosa" — tarjeta destacada de registro matutino en el
// Dashboard (propuesta §6.2/§7.2). Se autooculta cuando la ventana no
// está abierta (`GlucoseWindowState.isOpen == false`) — igual criterio
// de "widget autocontenido" que `GlucoseEntryCard`.
//
// Estado "pendiente" (borde ámbar) vs. "completado" (borde verde,
// mismo criterio de color que el resto de la app) — nunca alarmista
// (propuesta, Riesgos: "nunca mostrar alertas alarmistas").

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_reading_sheet.dart';

class GlucoseMorningReminderCard extends ConsumerWidget {
  const GlucoseMorningReminderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowState = ref.watch(glucoseWindowStateProvider);
    if (!windowState.isOpen) return const SizedBox.shrink();

    const color = Color(0xFFF59E0B); // ámbar — "pendiente", no alarma.

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showGlucoseReadingSheet(
          context,
          initialContext: GlucoseReadingContext.ayunas,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Es hora de tu registro de glucosa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'En ayunas, antes de comer o beber algo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
