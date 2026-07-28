// SPEC-119 (refactor god widget) — card del pilar Sueño extraída de
// dashboard_screen.dart, junto con sus handlers (_onTapUpdateSleep,
// _confirmDeleteSleepLog). ConsumerWidget autocontenido.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_card_ui.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_existing_log_dialog.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/features/health_sync/domain/health_permission_status.dart';

class SleepPillarCard extends ConsumerWidget {
  const SleepPillarCard({super.key, required this.state});

  final SleepState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFF818CF8);

    // Coherencia con el satélite (2026-06-11): el sueño se ancla al CICLO
    // metabólico, no al reloj. `currentCycleSleepProvider` (SPEC-188 v2) es la
    // regla canónica: devuelve el SleepLog del ciclo abierto, o null si el log
    // pertenece al ciclo anterior (ya cerrado). Cuando es null mostramos un
    // estado evocativo "esperando el descanso" en vez de arrastrar el dato de
    // anoche — igual que el satélite, que ya quedó en 0%.
    final log = ref.watch(currentCycleSleepProvider);
    final showLog = log != null;

    // SPEC-231: chip "entrada manual" cuando HealthKit no está activo.
    final healthPerm = ref.watch(healthPermissionStatusProvider);
    final isManual = healthPerm is! HealthPermissionGranted;

    final hours = showLog ? log.duration.inHours : 0;
    final minutes = showLog ? log.duration.inMinutes.remainder(60) : 0;
    final progress =
        showLog ? (log.duration.inMinutes / (8 * 60)).clamp(0.0, 1.0) : 0.0;
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
      children: showLog
          ? _loggedChildren(
              context: context,
              ref: ref,
              accent: accent,
              log: log,
              hours: hours,
              minutes: minutes,
              progress: progress,
              pct: pct,
              fmt: fmt,
              isManual: isManual,
            )
          : _waitingChildren(
              context: context, accent: accent, isManual: isManual),
    );
  }

  /// Estado normal: hay un sueño registrado dentro del ciclo actual.
  List<Widget> _loggedChildren({
    required BuildContext context,
    required WidgetRef ref,
    required Color accent,
    required SleepLog log,
    required int hours,
    required int minutes,
    required double progress,
    required int pct,
    required String Function(DateTime?) fmt,
    required bool isManual,
  }) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PillarCardUi.miniStat('Dormiste', '${hours}h ${minutes}m', accent,
              big: true),
          PillarCardUi.miniStat('Acostado', fmt(log.fellAsleep), Colors.white),
          PillarCardUi.miniStat('Despertaste', fmt(log.wokeUp), Colors.white),
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
        text: hours >= 7
            ? '✓ Sueño reparador — GH pulsátil activa durante ciclos REM'
            : 'Buscas sueño reparador: 7-9h activan la GH pulsátil que repara músculo y reduce inflamación.',
      ),
      const SizedBox(height: 18),
      // SPEC-231: chip "entrada manual" cuando HealthKit no está activo.
      if (isManual) PillarCardUi.manualDataChip(),
      // SPEC-106 / SPEC-108: el sheet precarga el último log si existe. Si ya
      // hay registro de HOY, primero pasa por un diálogo donde el usuario
      // elige editar o eliminar y recrear. Si no hay log, abre sheet limpio.
      PillarCardUi.primaryButton(
        label: 'Actualizar Registro',
        icon: Icons.nightlight_round,
        color: accent,
        onPressed: () => _onTapUpdateSleep(context, ref, state),
      ),
      const SizedBox(height: 10),
      PillarCardUi.secondaryButton(
        label: 'Eliminar registro y volver a registrar',
        icon: Icons.delete_outline_rounded,
        onPressed:
            state.isSaving ? null : () => _confirmDeleteSleepLog(context, ref),
      ),
    ];
  }

  /// Estado evocativo: el ciclo se reinició y aún no hay sueño de HOY. En
  /// vez de arrastrar el dato de la noche anterior, acompañamos al usuario
  /// hacia su descanso con un mensaje cálido sobre las fases del sueño.
  List<Widget> _waitingChildren({
    required BuildContext context,
    required Color accent,
    required bool isManual,
  }) {
    return [
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bedtime_rounded, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu descanso aún no empieza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nuevo día metabólico. El de anoche ya cerró.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      PillarCardUi.benefitChip(
        accent: accent,
        text: 'Mientras descansás, tu cuerpo recorre sus fases: sueño ligero, '
            'profundo y REM. En el profundo repara músculo; en REM ordena '
            'memoria y hormonas.',
      ),
      const SizedBox(height: 18),
      // SPEC-231: chip "entrada manual" cuando HealthKit no está activo.
      if (isManual) PillarCardUi.manualDataChip(),
      PillarCardUi.primaryButton(
        label: 'Registrar Sueño',
        icon: Icons.nightlight_round,
        color: accent,
        onPressed: () => _onTapRegisterFresh(context),
      ),
    ];
  }

  /// Abre el sheet de sueño en limpio (sin precargar la noche anterior, que
  /// pertenece a un ciclo ya cerrado).
  Future<void> _onTapRegisterFresh(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SleepInputSheet(),
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
