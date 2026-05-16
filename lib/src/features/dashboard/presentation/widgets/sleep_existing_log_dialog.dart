// SPEC-108: diálogo que aparece cuando el usuario toca "Actualizar
// Registro" y ya existe un registro de sueño del día. Muestra los
// datos actuales y ofrece tres rutas:
//   - Editar este registro (abre sheet con campos precargados).
//   - Eliminar y registrar nuevo (dispara confirm + delete + sheet).
//   - Cancelar.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';

enum SleepExistingLogChoice { edit, replace, cancel }

class SleepExistingLogDialog extends StatelessWidget {
  final SleepLog log;

  const SleepExistingLogDialog({super.key, required this.log});

  /// Muestra el diálogo y resuelve con la opción elegida.
  static Future<SleepExistingLogChoice> show(
    BuildContext context, {
    required SleepLog log,
  }) async {
    final result = await showDialog<SleepExistingLogChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SleepExistingLogDialog(log: log),
    );
    return result ?? SleepExistingLogChoice.cancel;
  }

  String _fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF818CF8);
    final duration = log.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final quality = log.subjectiveQuality;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: const Icon(
        Icons.nightlight_round,
        color: accent,
        size: 32,
      ),
      title: const Text(
        'Ya tienes un registro de sueño hoy',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _row('Acostado', _fmt(log.fellAsleep)),
                const SizedBox(height: 6),
                _row('Despertaste', _fmt(log.wokeUp)),
                const SizedBox(height: 6),
                _row('Duración', '${hours}h ${minutes}m'),
                if (quality != null) ...[
                  const SizedBox(height: 6),
                  _row('Calidad', _starsLabel(quality)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¿Qué quieres hacer?',
            style: TextStyle(
              color: Color(0xFFB6C3D1),
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: 8,
      actions: [
        ElevatedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(SleepExistingLogChoice.edit),
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
          label: const Text(
            'Editar este registro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(SleepExistingLogChoice.replace),
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          label: const Text(
            'Eliminar y registrar nuevo',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(SleepExistingLogChoice.cancel),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _starsLabel(int n) {
    final filled = '★' * n.clamp(0, 5);
    final empty = '☆' * (5 - n.clamp(0, 5));
    return '$filled$empty';
  }
}
