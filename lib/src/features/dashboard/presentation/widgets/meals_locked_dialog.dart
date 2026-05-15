// SPEC-105: diálogo educativo cuando el usuario intenta registrar
// una comida mientras hay ayuno activo. Explica por qué la card
// está bloqueada y ofrece un acceso directo al card de Ayuno.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class MealsLockedDuringFastingDialog extends StatelessWidget {
  const MealsLockedDuringFastingDialog({super.key});

  /// Muestra el diálogo. Resuelve con `true` si el usuario eligió
  /// "Ir a tarjeta de Ayuno", `null` o `false` si solo cerró.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const MealsLockedDuringFastingDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(
        Icons.lock_clock_rounded,
        color: AppColors.metabolicGreen,
        size: 32,
      ),
      title: const Text(
        'Estás en ayuno activo',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'Registrar una comida ahora rompería tu protocolo de ayuno y '
        'contaminaría el cómputo de tu IMR.\n\n'
        'Para registrar comidas, primero termina tu ayuno desde la '
        'tarjeta de Ayuno.',
        style: TextStyle(
          color: Color(0xFFB6C3D1),
          fontSize: 14,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Entendido',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.timer_rounded, size: 18, color: Colors.white),
          label: const Text(
            'Ir a tarjeta de Ayuno',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.metabolicGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
