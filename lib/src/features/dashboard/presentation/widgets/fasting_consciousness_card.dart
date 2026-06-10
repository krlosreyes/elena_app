// SPEC-119 (refactor god widget) — card del pilar Ayuno ("Ayuno Consciente")
// extraída de dashboard_screen.dart junto con todo su clúster de helpers:
// chip de protocolo, timeline, hitos, botón principal y pickers de hora.
// ConsumerWidget autocontenido; recibe el FastingState por constructor.
//
// Nota: `_showManualTimePicker` se duplica aquí porque el dashboard la sigue
// usando en `_buildFastingEndOverlay` (que permanece en la pantalla). La
// función solo depende de fastingProvider + diálogos de Flutter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_history_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/domain/relative_day_label.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class FastingConsciousnessCard extends ConsumerWidget {
  const FastingConsciousnessCard({super.key, required this.state});

  final FastingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = state.isActive;
    const accent = AppColors.metabolicGreen;
    final pct = (state.progressPercentage.clamp(0.0, 1.0) * 100).round();

    // SPEC-113.feat: cuando NO hay ayuno activo, calculamos el próximo
    // momento de cierre de ventana de alimentación basado en el
    // `lastMealGoal` del usuario. Si esa hora ya pasó hoy → mañana.
    // `lastMealGoal` es nullable: si el perfil aún no lo definió, el
    // countdown no aplica y el clock cae al placeholder.
    final user = ref.watch(currentUserStreamProvider).value;
    DateTime? nextFastingTime;
    if (!isActive && user != null) {
      final lastMeal = user.profile.lastMealGoal;
      if (lastMeal != null) {
        final now = DateTime.now();
        var candidate = DateTime(
          now.year,
          now.month,
          now.day,
          lastMeal.hour,
          lastMeal.minute,
        );
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        nextFastingTime = candidate;
      }
    }

    final stateLabel = isActive
        ? 'En curso'
        : (nextFastingTime != null ? 'Próximo ayuno' : 'En espera');

    final benefits = isActive
        ? const [
            'Estás reduciendo glucosa y mejorando sensibilidad a la insulina.',
            'A partir de 12h se activa la cetosis y la autofagia inicial.',
          ]
        : const [
            'Reduce resistencia a la insulina desde la 1ª hora',
            'Regula glucosa en ayunas y mejora sensibilidad metabólica',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: título + estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ayuno Consciente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  stateLabel,
                  style: const TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // SPEC-119: fila de metadatos del protocolo. El cronómetro
          // vivo HH:MM:SS ya está en el hero (FastingHeroDisplay del
          // CircadianClock), no duplicamos aquí. La tarjeta se
          // identifica como "panel de control y contexto": qué
          // protocolo está activo y qué hito viene a continuación.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda: PROTOCOLO (chip clickable).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROTOCOLO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildProtocolChip(
                        context: context,
                        ref: ref,
                        protocol: state.fastingProtocol,
                        isActive: isActive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Columna derecha: HITO SIGUIENTE (solo visible si activo).
              if (isActive)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HITO SIGUIENTE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNextMilestone(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progreso fina
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progressPercentage.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          // SPEC-102: etiquetas sutiles en los extremos de la barra
          // con la hora de inicio y la hora estimada de fin del
          // ayuno. Patrón Apple Health / Oura — informa de un vistazo
          // el rango temporal sin invadir la jerarquía visual.
          if (isActive && state.startTime != null) ...[
            const SizedBox(height: 4),
            _buildFastingTimeline(
              start: state.startTime!,
              targetHours: state.targetHours,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            // SPEC-113.feat: el texto debajo se adapta al estado.
            // SPEC-119: cuando hay ayuno activo, agregamos el residual
            // temporal "faltan Xh Ym" — alto valor accionable: el usuario
            // sabe cuánto le queda sin tener que hacer la resta mental.
            isActive
                ? '$pct% completado${_formatTargetRemaining(state)}'
                : (nextFastingTime != null
                    ? 'Inicia ${nextFastingTime.hour.toString().padLeft(2, '0')}:${nextFastingTime.minute.toString().padLeft(2, '0')}'
                    : 'Listo para iniciar tu ayuno'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          // Beneficios
          Text(
            isActive ? 'BENEFICIOS ACTUALES' : 'BENEFICIOS AL INICIAR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Botón principal: iniciar / finalizar.
          //
          // SPEC-101:
          // - Si el usuario ya completó ayuno hoy y NO hay uno activo,
          //   el botón "Iniciar Ayuno" queda deshabilitado.
          // - Si está activo y progress < 100%, "Finalizar Ayuno" abre
          //   un diálogo de confirmación con beneficios obtenidos.
          // - Si está activo y progress >= 100%, flow actual (picker).
          _buildFastingPrimaryButton(
            context: context,
            ref: ref,
            state: state,
            isActive: isActive,
            accent: accent,
          ),
          // SPEC-97: el botón "Corregir hora de inicio" SOLO aparece
          // cuando hay ayuno activo. Antes aparecía siempre y al
          // tocarlo en estado "En espera" iniciaba ventana de comida
          // por error (confirmManualFastingEnd con isFeeding=false).
          //
          // Auditoría F3 (2026-06-08) → reabierto (2026-06-09): visible para
          // todos, pero `_showCorrectStartTimePicker` CLAMPEA la corrección
          // para que nunca deje el ayuno ≥100% (evita el "100% al iniciar").
          if (isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () => _showCorrectStartTimePicker(context, ref, state),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  Icons.access_time_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                label: Text(
                  'Corregir hora de inicio del ayuno',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNextMilestone(FastingState state) {
    final remaining = state.timeRemainingForNextMilestone;
    if (remaining == Duration.zero) {
      // Estamos en autofagia o fase final — no hay próximo hito.
      return state.metabolicMilestone;
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final timeText = hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
    // Texto del hito en minúsculas estilo "Quema de grasa".
    String milestone;
    if (state.duration.inHours < 12) {
      milestone = 'Descenso de insulina';
    } else if (state.duration.inHours < 18) {
      milestone = 'Quema de grasa';
    } else if (state.duration.inHours < 24) {
      milestone = 'Autofagia';
    } else {
      milestone = 'Regeneración';
    }
    return '$milestone en $timeText';
  }

  /// SPEC-119: residual hasta cerrar el target (`targetHours`).
  /// Devuelve `' · faltan Xh Ym'` o `' · objetivo cumplido'`.
  /// El prefijo con ` · ` permite concatenar tras `$pct% completado`.
  String _formatTargetRemaining(FastingState state) {
    if (state.startTime == null) return '';
    final targetSeconds = state.targetHours * 3600;
    final elapsedSeconds = state.duration.inSeconds;
    final remainingSeconds = targetSeconds - elapsedSeconds;
    if (remainingSeconds <= 0) return ' · objetivo cumplido';
    final remaining = Duration(seconds: remainingSeconds);
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final t = h == 0 ? '${m}m' : '${h}h ${m}m';
    return ' · faltan $t';
  }

  Widget _buildFastingTimeline({
    required DateTime start,
    required int targetHours,
  }) {
    final DateTime now = DateTime.now();
    final DateTime estimatedEnd = start.add(Duration(hours: targetHours));

    final mutedStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    final dimmerStyle = mutedStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.30),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timelineEndpoint(
          dateTime: start,
          now: now,
          baseStyle: mutedStyle,
          qualifierStyle: dimmerStyle,
        ),
        _timelineEndpoint(
          dateTime: estimatedEnd,
          now: now,
          baseStyle: mutedStyle,
          qualifierStyle: dimmerStyle,
        ),
      ],
    );
  }

  Widget _timelineEndpoint({
    required DateTime dateTime,
    required DateTime now,
    required TextStyle baseStyle,
    required TextStyle qualifierStyle,
  }) {
    final qualifier = RelativeDayLabel.qualifier(dateTime, now);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatHHmm(dateTime), style: baseStyle),
        if (qualifier.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text('·$qualifier', style: qualifierStyle),
        ],
      ],
    );
  }

  static String _formatHHmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// SPEC-101: botón principal del card de Ayuno.
  ///
  /// - Estado "activo": label rojo "Finalizar Ayuno". Si progress<100%
  ///   muestra diálogo de confirmación con beneficios. Si >=100%, va
  ///   directo al picker (flow actual).
  /// - Estado "inactivo": label verde "Iniciar Ayuno". Si el usuario
  ///   ya completó un ayuno hoy, queda deshabilitado y al tocar
  ///   muestra snackbar.
  Widget _buildFastingPrimaryButton({
    required BuildContext context,
    required WidgetRef ref,
    required FastingState state,
    required bool isActive,
    required Color accent,
  }) {
    final bool completedToday =
        !isActive && ref.watch(hasCompletedFastingTodayProvider);
    final bool disabled = state.isSaving || (completedToday && !isActive);

    final Color bgColor;
    if (disabled && !isActive) {
      bgColor = Colors.white.withValues(alpha: 0.08);
    } else if (isActive) {
      bgColor = Colors.redAccent;
    } else {
      bgColor = accent;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: disabled
            ? () {
                // En estado deshabilitado por completedToday queremos
                // explicar por qué no se puede tocar.
                if (completedToday && !isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ya completaste tu ayuno de hoy. '
                        'Vuelve mañana para iniciar el siguiente.',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            : () => _handleFastingPrimaryTap(context, ref, state, isActive),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: state.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isActive
                    ? Icons.stop_circle_outlined
                    : (completedToday
                        ? Icons.check_circle_outline
                        : Icons.play_circle_outline),
                color: Colors.white
                    .withValues(alpha: (disabled && !isActive) ? 0.5 : 1.0),
                size: 22,
              ),
        label: Text(
          isActive
              ? 'Finalizar Ayuno'
              : (completedToday ? 'Ayuno de hoy completado' : 'Iniciar Ayuno'),
          style: TextStyle(
            color: Colors.white
                .withValues(alpha: (disabled && !isActive) ? 0.5 : 1.0),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFastingPrimaryTap(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
    bool isActive,
  ) async {
    if (isActive) {
      // Si llegó al 100%, flow actual (picker de hora de fin).
      if (state.progressPercentage >= 1.0) {
        await _showManualTimePicker(context, ref, isFeeding: false);
        return;
      }
      // SPEC-101: confirmación temprana con beneficios obtenidos.
      final confirm = await EarlyFastingEndDialog.show(
        context,
        elapsed: state.duration,
        targetHours: state.targetHours,
        phase: state.phase,
      );
      if (confirm == true) {
        await ref
            .read(fastingProvider.notifier)
            .confirmManualFastingEnd(DateTime.now());
      }
      return;
    }

    // No activo: iniciar.
    await ref.read(fastingProvider.notifier).startFasting();
  }

  /// SPEC-98: chip clickable que muestra el protocolo activo y abre
  /// el selector. Si el ayuno está en curso, el chip queda
  /// deshabilitado (cambiar protocolo a mitad de ayuno corrompería
  /// el cómputo de progreso y de fase).
  Widget _buildProtocolChip({
    required BuildContext context,
    required WidgetRef ref,
    required String protocol,
    required bool isActive,
  }) {
    final double alpha = isActive ? 0.35 : 0.85;
    return InkWell(
      onTap: () => _onProtocolChipTap(context, ref, protocol, isActive),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              protocol,
              style: TextStyle(
                color: Colors.white.withValues(alpha: alpha),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isActive ? Icons.lock_outline_rounded : Icons.expand_more_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onProtocolChipTap(
    BuildContext context,
    WidgetRef ref,
    String currentProtocol,
    bool isActive,
  ) async {
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes cambiar protocolo durante un ayuno activo. '
            'Finaliza primero.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final selected = await ProtocolSelectorSheet.show(
      context,
      currentProtocol: currentProtocol,
    );
    if (selected == null || selected == currentProtocol) return;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    await ref.read(profileControllerProvider.notifier).updateFastingProtocol(
          currentUser: user,
          protocol: selected,
        );
  }

  /// SPEC-97: picker dedicado para corregir la hora de inicio del
  /// ayuno activo. Distinto de `_showManualTimePicker`, que finaliza
  /// el ayuno (crea ventana de comida) y NO debe usarse para corregir.
  Future<void> _showCorrectStartTimePicker(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime currentStart = state.startTime ?? now;
    // Clamp (F3): el inicio no puede quedar tan atrás que el ayuno llegue a
    // ≥100% al corregir. `maxBack` = duración del target; con 1 min de margen
    // el progreso queda estrictamente por debajo del 100%.
    final int targetHours = state.targetHours > 0 ? state.targetHours : 24;
    final Duration maxBack = Duration(hours: targetHours);
    final DateTime targetEarliest =
        now.subtract(maxBack).add(const Duration(minutes: 1));
    final DateTime hardEarliest = now.subtract(const Duration(hours: 24));
    // El más RECIENTE de ambos límites (el más restrictivo).
    final DateTime earliest =
        targetEarliest.isAfter(hardEarliest) ? targetEarliest : hardEarliest;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStart.isBefore(earliest) ? earliest : currentStart,
      firstDate: earliest,
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.metabolicGreen,
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentStart),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.metabolicGreen,
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validación defensiva (también vive en el notifier).
    if (finalDateTime.isAfter(now)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de inicio no puede ser futura.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (now.difference(finalDateTime).inHours > 24) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La corrección no puede ser más de 24h atrás.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // Clamp F3: no dejar el ayuno ≥100% al corregir.
    if (now.difference(finalDateTime) >= maxBack) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esa hora dejaría tu ayuno ya completo. Elige una hora más '
            'reciente.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await ref
        .read(fastingProvider.notifier)
        .correctFastingStartTime(finalDateTime);
  }

  /// Copia local de `_showManualTimePicker` (el dashboard mantiene la suya
  /// para `_buildFastingEndOverlay`). Solo se invoca aquí con isFeeding=false
  /// cuando el ayuno llegó al 100%.
  Future<void> _showManualTimePicker(BuildContext context, WidgetRef ref,
      {required bool isFeeding}) async {
    final DateTime now = DateTime.now();
    final fastingState = ref.read(fastingProvider);
    final Color primaryColor =
        isFeeding ? Colors.orangeAccent : AppColors.metabolicGreen;
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 7)),
        lastDate: now.add(const Duration(days: 1)),
        builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: primaryColor),
                dialogTheme:
                    DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
            child: child!));
    if (pickedDate == null) return;
    if (!context.mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: primaryColor),
                dialogTheme:
                    DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
            child: child!));
    if (pickedTime == null) return;
    final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month,
        pickedDate.day, pickedTime.hour, pickedTime.minute);
    if (isFeeding) {
      ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime);
    } else {
      if (fastingState.isActive) {
        ref
            .read(fastingProvider.notifier)
            .confirmManualFastingEnd(finalDateTime);
      } else {
        ref.read(fastingProvider.notifier).startFastingManual(finalDateTime);
      }
    }
  }
}
