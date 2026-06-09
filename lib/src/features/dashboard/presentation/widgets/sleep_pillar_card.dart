// SPEC-119 (refactor god widget) — card del pilar Sueño extraída de
// dashboard_screen.dart, junto con sus handlers (_onTapUpdateSleep,
// _confirmDeleteSleepLog). ConsumerWidget autocontenido.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_existing_log_dialog.dart';

class SleepPillarCard extends ConsumerWidget {
  const SleepPillarCard({super.key, required this.state});

  final SleepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFF818CF8);
    final log = state.lastLog;
    final hasLog = log != null;
    final hours = hasLog ? log.duration.inHours : 0;
    final minutes = hasLog ? log.duration.inMinutes.remainder(60) : 0;
    final progress =
        hasLog ? (log.duration.inMinutes / (8 * 60)).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();

    String fmt(DateTime? dt) {
      if (dt == null) return '—';
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return PillarCardUi.shell(
      title: 'Soporte Metabólico',
      badge: 'Sueño',
      accent: accent,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PillarCardUi.miniStat(
                'Dormiste', hasLog ? '${hours}h ${minutes}m' : '—', accent,
                big: true),
            PillarCardUi.miniStat('Acostado', fmt(log?.fellAsleep), Colors.white),
            PillarCardUi.miniStat('Despertaste', fmt(log?.wokeUp), Colors.white),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('🚩', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Meta: 7-9 horas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PillarCardUi.progressBar(progress, accent),
        const SizedBox(height: 6),
        PillarCardUi.completionLabel(pct),
        const SizedBox(height: 16),
        PillarCardUi.benefitChip(
          accent: accent,
          text: hasLog && hours >= 7
              ? '✓ Sueño reparador — GH pulsátil activa durante ciclos REM'
              : 'Buscas sueño reparador: 7-9h activan la GH pulsátil que repara músculo y reduce inflamación.',
        ),
        const SizedBox(height: 18),
        // SPEC-106 / SPEC-108: el sheet precarga el último log si existe. Si ya
        // hay registro de HOY, primero pasa por un diálogo donde el usuario
        // elige editar o eliminar y recrear. Si no hay log, abre sheet limpio.
        PillarCardUi.primaryButton(
          label: hasLog ? 'Actualizar Registro' : 'Registrar Sueño',
          icon: Icons.nightlight_round,
          color: accent,
          onPressed: () => _onTapUpdateSleep(context, ref, state),
        ),
        const SizedBox(height: 10),
        if (hasLog)
          PillarCardUi.secondaryButton(
            label: 'Eliminar registro y volver a registrar',
            icon: Icons.delete_outline_rounded,
            onPressed: state.isSaving
                ? null
                : () => _confirmDeleteSleepLog(context, ref),
          ),
      ],
    );
  }

  /// SPEC-108: handler unificado del botón "Actualizar Registro".
  Future<void> _onTapUpdateSleep(
      BuildContext context, WidgetRef ref, SleepState state) async {
    final log = state.lastLog;
    final now = DateTime.now();

    final bool hasTodayLog = log != null &&
        log.wokeUp.year == now.year &&
        log.wokeUp.month == now.month &&
        log.wokeUp.day == now.day;

    if (!hasTodayLog) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SleepInputSheet(initial: log),
      );
      return;
    }

    final choice = await SleepExistingLogDialog.show(context, log: log);
    if (!context.mounted) return;

    switch (choice) {
      case SleepExistingLogChoice.edit:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SleepInputSheet(initial: log),
        );
        break;
      case SleepExistingLogChoice.replace:
        await _confirmDeleteSleepLog(context, ref);
        break;
      case SleepExistingLogChoice.cancel:
        break;
    }
  }

  /// SPEC-106: confirmación previa a eliminar el registro de sueño.
  Future<void> _confirmDeleteSleepLog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          '¿Eliminar registro de sueño?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Esta acción borra el registro actual de Firestore. '
          'Después podrás capturar uno nuevo desde cero.',
          style: TextStyle(
            color: Color(0xFFB6C3D1),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(sleepProvider.notifier).deleteLastLog();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SleepInputSheet(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
