// Acceso al reloj circadiano desde Hoy (23-nov).
//
// El 30-oct el reloj salió de la portada de Hoy (competía con la acción
// principal) y su acceso quedó en Progreso. Eso no era coherente: el reloj
// muestra el día de HOY (ventana de comida, ayuno y descanso, y dónde
// estás ahora), no un resultado acumulado. Vuelve a Hoy como una fila
// compacta debajo de "Tu día metabólico", que es la sección que el reloj
// explica en forma de 24 horas. La pantalla completa sigue siendo
// CircadianClockScreen (ruta /reloj).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class CircadianClockEntryCard extends StatelessWidget {
  const CircadianClockEntryCard({super.key});

  static const routePath = '/reloj';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C1422),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(routePath),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppColors.metabolicGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu reloj circadiano',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu día en 24 horas: comida, ayuno y descanso',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
