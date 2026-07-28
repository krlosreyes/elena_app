// SPEC-254: diálogo de confirmación al iniciar un nuevo ayuno cuando
// todavía hay comidas visibles en el Día Metabólico actual.
//
// Contexto (2026-07-08): Carlos reportó reiteradamente que las comidas
// "desaparecían" del historial. Tras auditar todo el pipeline de
// nutrición (SPEC-251/252/253/253.1) y revisar Firestore directamente,
// se confirmó que el mecanismo no era una pérdida de datos: es el
// comportamiento cycle-aware INTENCIONAL del Día Metabólico (SPEC-149,
// Constitución §1) — cada ciclo metabólico solo muestra sus propias
// comidas. Al iniciar un nuevo ayuno (acción consciente, botón "Iniciar
// ayuno" / "Empezar mi siguiente ayuno"), el ciclo anterior se cierra y
// uno nuevo se abre con `startedAt = ahora`. Cualquier comida registrada
// ANTES de ese instante dentro del ciclo que cierra deja de estar en la
// ventana del ciclo nuevo — sigue en Firestore, solo que "Hoy" ya no la
// incluye.
//
// El bug real era de PRODUCTO/UX, no de datos: no había ninguna señal
// que le avisara al usuario que tocar "Iniciar ayuno" iba a mover
// "Hoy" a un ciclo nuevo y sacar de la vista las comidas ya registradas.
// Este diálogo cierra ese gap — solo aparece si hay algo que se movería
// fuera de la vista, y deja clarísimo que los datos NO se pierden.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class NewCycleMealsWarningDialog extends StatelessWidget {
  final int mealsCount;

  const NewCycleMealsWarningDialog({super.key, required this.mealsCount});

  /// Muestra el diálogo y resuelve con `true` si el usuario confirma
  /// iniciar el ayuno de todas formas, `false`/`null` si cancela.
  static Future<bool?> show(
    BuildContext context, {
    required int mealsCount,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NewCycleMealsWarningDialog(mealsCount: mealsCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsLabel = mealsCount == 1
        ? '1 comida registrada'
        : '$mealsCount comidas registradas';

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        '¿Iniciar tu próximo ayuno?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tenés $mealsLabel en tu Día Metabólico actual',
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
          const SizedBox(height: 14),
          const Text(
            'Al iniciar el ayuno arrancás un nuevo Día Metabólico. Esas '
            'comidas van a quedar fuera de la vista de "Hoy" — se '
            'conservan en tu historial, no se borran.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: AppColors.metabolicGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC0392B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text(
            'Sí, iniciar ayuno',
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
