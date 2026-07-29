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

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/fasting/application/fasting_history_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/fasting/domain/eating_window_advisory.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_benefits.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/domain/relative_day_label.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/new_cycle_meals_warning_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_day_copy.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/metabolic_day_explainer_sheet.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/features/streak/domain/fasting_symptom_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Línea que nombra el Día Metabólico en el Dashboard y abre su
/// explicación (28-jul).
///
/// El texto cambia con el estado porque la regla que enseña es distinta
/// en cada uno, y enseñarla cuando es verdad se recuerda mejor que
/// leerla en abstracto:
///
/// - Con ayuno activo, el ciclo YA está corriendo → se dice que empezó
///   con ese ayuno.
/// - Sin ayuno, el ciclo no ha empezado (constitución §1: "si no hay
///   ciclo abierto, el día metabólico no ha empezado todavía") → se dice
///   qué lo va a abrir.
///
/// Con protocolo 'Ninguno' no se promete nada de eso: ese usuario está
/// en modo calendárico y su día sí cierra a medianoche. Decirle que su
/// día lo marca su ayuno sería falso.
class _MetabolicDayLabel extends StatelessWidget {
  final bool isActive;
  final String fastingProtocol;

  const _MetabolicDayLabel({
    required this.isActive,
    required this.fastingProtocol,
  });

  @override
  Widget build(BuildContext context) {
    final String texto;
    if (usaDiaCalendario(fastingProtocol)) {
      texto = 'Tu día metabólico va con el calendario';
    } else if (isActive) {
      texto = 'Tu día metabólico empezó con este ayuno';
    } else {
      texto = 'Tu día metabólico empieza al iniciar el ayuno';
    }

    return Semantics(
      button: true,
      label: '$texto. Toca para saber qué es tu día metabólico.',
      child: InkWell(
        onTap: () => showMetabolicDayExplainerSheet(
          context,
          fastingProtocol: fastingProtocol,
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  texto,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    // Auditoría 2026-07-27 (C-01): esta lista era estática y afirmaba, a
    // cualquier usuario con un ayuno activo, que ya estaba "reduciendo
    // glucosa y mejorando sensibilidad a la insulina" y que "a partir de
    // 16h se activa la cetosis y la autofagia inicial" — dos umbrales que
    // no coinciden con el enum canónico (cetosis a las 18h, autofagia a
    // las 24h) y que se mostraban idénticos a los 17 minutos de ayuno que
    // a las 20 horas. Ahora los beneficios se derivan de la fase real vía
    // `FastingBenefits`, que ya existía en el dominio, está alineado con
    // CIRCADIAN_BIBLIOGRAPHY.md §2 y tiene tests propios.
    final benefits = isActive
        ? FastingBenefits.benefitsFor(state.phase, state.duration)
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
          const SizedBox(height: 8),
          // 28-jul: el Día Metabólico no se nombraba en NINGÚN sitio del
          // estado normal del Dashboard. Solo aparecía al cerrarse un
          // ciclo, en el diálogo de comidas y en un estado concreto del
          // pilar sueño — es decir, el usuario se enteraba de que existe
          // la primera vez que uno se le cerraba, cuando ya había pasado
          // algo que no entendía. Mismo defecto que teníamos con las
          // reservas de racha.
          //
          // Va aquí porque esta tarjeta ES el día metabólico dibujado:
          // arranca con el ciclo y lo acompaña entero. Nombrarlo donde ya
          // se está mirando cuesta una línea.
          _MetabolicDayLabel(
            isActive: isActive,
            fastingProtocol: state.fastingProtocol,
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
          // I-06 (auditoría 2026-07-27): aviso cuando la ventana de
          // alimentación abriría después del cierre circadiano. Se observó
          // en ejecución un ayuno 07:05 → 23:05, es decir, la app guiando a
          // comer a las once de la noche mientras su propio IMR penaliza al
          // 50% comer después de las 21:30. Es una recomendación, no un
          // bloqueo: el usuario sigue mandando sobre su ayuno.
          if (isActive && state.startTime != null)
            _buildEatingWindowAdvisory(state),
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
    // Auditoría 2026-07-27 (C-01): este método tenía sus propios umbrales
    // hardcodeados (12/18/24h) y su propia tabla de nombres, ambos
    // divergentes del enum canónico y del anillo del Dashboard. El
    // resultado era que la misma pantalla anunciaba dos hitos distintos
    // para el mismo instante. Ahora el nombre viene del dominio y no hay
    // ningún umbral fisiológico en esta capa.
    final milestone = state.nextPhase?.milestoneName;
    if (milestone == null) return state.metabolicMilestone;
    return '$milestone en $timeText';
  }

  /// I-06 (auditoría 2026-07-27): franja de aviso cuando el objetivo de
  /// ayuno actual dejaría la ventana de alimentación abriendo después del
  /// bloqueo intestinal. La lógica vive en `EatingWindowAdvisory` (dominio
  /// puro, testeable); aquí solo se pinta. Devuelve `SizedBox.shrink()`
  /// —coste cero— cuando la ventana sí respeta el cierre, que es el caso
  /// normal de un ayuno bien planteado.
  Widget _buildEatingWindowAdvisory(FastingState state) {
    final advisory = EatingWindowAdvisory.evaluate(
      start: state.startTime!,
      targetHours: state.targetHours,
    );
    final mensaje = advisory.mensaje;
    if (mensaje == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.nightlight_outlined,
              size: 15,
              color: Color(0xFFF59E0B),
              semanticLabel: 'Aviso de cierre circadiano',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    // Bugfix 2026-06-11: completar un ayuno YA NO bloquea iniciar el siguiente.
    // El producto se ancla al usuario, no al reloj: en ayuno intermitente real
    // (16:8 diario) la ventana cruza la noche y se inicia un nuevo ayuno el
    // mismo día. La completación queda como confirmación visual ("Iniciar
    // nuevo ayuno"), no como candado. El provider hasCompletedFastingToday
    // sigue vivo para resumen diario / paywall; aquí solo informa el label.
    final bool completedToday =
        !isActive && ref.watch(hasCompletedFastingTodayProvider);
    final bool disabled = state.isSaving;

    final Color bgColor;
    if (isActive) {
      bgColor = Colors.redAccent;
    } else {
      bgColor = accent;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: disabled
            ? null
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
                    : Icons.play_circle_outline,
                color: Colors.white,
                size: 22,
              ),
        label: Text(
          isActive
              ? 'Finalizar Ayuno'
              : (completedToday ? 'Iniciar nuevo ayuno' : 'Iniciar ayuno'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// SPEC-257 §4 Eje D: pregunta breve tras un cierre anticipado —
  /// mareo, temblor o palpitaciones son la señal de alarma dura que
  /// Suárez describe (fuente primaria: preguntaleafrank.com "El Ayuno
  /// Intermitente", "quítese" ante esos síntomas). Un "sí" se persiste
  /// en `FastingSymptomLog` (SharedPreferences, ventana de 7 días) y
  /// `AdaptiveEngine` lo lee para sugerir `simplify` de inmediato —
  /// sin esperar a que la adherencia semanal caiga lo bastante como
  /// para que `EngagementLevel.critico` lo detecte por su cuenta.
  Future<void> _askHypoglycemiaSymptoms(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final reported = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Antes de seguir…',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          '¿Sentiste mareo, temblor o palpitaciones antes de terminar el '
          'ayuno? Nos ayuda a ajustar tu protocolo si hace falta.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Prefiero no decir'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Sí, tuve síntomas',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (reported == true) {
      await FastingSymptomLog.reportHypoglycemia(
        ref.read(sharedPreferencesProvider),
      );
    }
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
        // SPEC-257 Eje D: solo se pregunta por síntomas cuando el
        // usuario termina el ayuno ANTES de tiempo — es la situación
        // real que Suárez describe (romper por malestar), no un cierre
        // normal al llegar al 100%. Pregunta corta, opcional, sin
        // bloquear: "prefiero no decir" es una opción legítima.
        if (context.mounted) {
          await _askHypoglycemiaSymptoms(context, ref);
        }
      }
      return;
    }

    // No activo: iniciar.

    // GATE MÉDICO — verificado en Simulador, 28-jul-2026.
    //
    // `FastingEligibility.assess()` ya se consultaba en este archivo,
    // pero SOLO para pintar el selector de protocolo (`_onProtocolChipTap`).
    // El botón de iniciar no lo miraba. Resultado comprobado: con
    // "Embarazo o lactancia" declarado, el protocolo quedaba recortado a
    // "Ninguno" con su candado… y el ayuno arrancaba igual, contando
    // hitos y celebrando, con la app acompañando.
    //
    // El recorte del protocolo protege el DATO; esto protege la ACCIÓN.
    // Sin las dos, el cribado del onboarding es decorativo.
    final userForFastingGate = ref.read(currentUserStreamProvider).valueOrNull;
    if (userForFastingGate != null) {
      final gate = FastingEligibility.assess(userForFastingGate);
      if (gate.blocked) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.health_and_safety_outlined,
                    color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Ayuno no recomendado',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
            content: Text(
              // El motivo lo redacta el propio gate, para que no haya dos
              // versiones del criterio médico.
              '${gate.reason}\n\nPuedes cambiar lo que declaraste desde '
              'Perfil › Datos biométricos si tu situación cambia.',
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 13, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ENTENDIDO',
                    style: TextStyle(
                        color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return;
      }
    }

    // SPEC-254: avisar si iniciar el ayuno va a sacar de la vista comidas
    // ya registradas en el ciclo actual (ver
    // new_cycle_meals_warning_dialog.dart — el mecanismo NO es pérdida de
    // datos, es la ventana cycle-aware del Día Metabólico moviéndose a un
    // ciclo nuevo, sin aviso previo al usuario).
    final mealsCount = ref.read(nutritionProvider).todayLogs.length;
    if (mealsCount > 0) {
      final confirm = await NewCycleMealsWarningDialog.show(
        context,
        mealsCount: mealsCount,
      );
      if (confirm != true) return;
    }
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

    // SPEC-257 Eje A: gate médico calculado sobre el usuario actual —
    // se lee ANTES de abrir el sheet para poder pintar los protocolos
    // fuera de alcance como bloqueados en vez de dejar que el usuario
    // los elija y recién rechazarlos después.
    final userForGate = ref.read(currentUserStreamProvider).valueOrNull;
    final eligibility =
        userForGate == null ? null : FastingEligibility.assess(userForGate);

    final selected = await ProtocolSelectorSheet.show(
      context,
      currentProtocol: currentProtocol,
      eligibility: eligibility,
    );
    if (selected == null || selected == currentProtocol) return;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    // SPEC-257 Eje C: antes este guardrail solo vivía en el onboarding
    // (§RF-137-08.D, salto exacto a 20:4). Un usuario Excitado podía
    // subir de protocolo desde el dashboard sin aviso — el mismo riesgo
    // que Suárez describe (tensión, sueño peor, adherencia rota) pero
    // sin la señal. Se generaliza aquí con la misma regla que
    // `onboarding_screen._handleProtocolChange`: cualquier salto que
    // suba de nivel y quede por encima de 16:8, con SN Excitado o
    // `unknown` (tratado como Excitado solo para esta decisión).
    int rank(String p) => FastingEligibility.ladder.indexOf(p);
    final declaredNS = NervousSystem.fromPersistenceKey(user.nervousSystem);
    final guardrailNS = declaredNS == NervousSystem.unknown
        ? NervousSystem.excited
        : declaredNS;
    final isUpwardPastSixteenEight =
        rank(selected) > rank('16:8') && rank(selected) > rank(currentProtocol);
    final warningKey = '$selected-on-excited';
    final needsGuardrail = guardrailNS == NervousSystem.excited &&
        isUpwardPastSixteenEight &&
        user.protocolWarningAccepted != warningKey;

    String finalProtocol = selected;
    String? warningToAccept;
    if (needsGuardrail && context.mounted) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('🤔 Una sugerencia honesta'),
          content: Text(
            'Las personas con perfil Excitado (sueño superficial, '
            'tensión baseline, apetito matutino bajo) suelen tolerar '
            '$selected mejor después de adaptarse con 16:8 unas semanas.\n\n'
            'Empezar directo con $selected puede aumentar tu tensión, '
            'empeorar tu sueño y romper la adherencia. No es '
            'prohibición — es algo que hemos visto.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('16:8'),
              child: const Text('Empezar con 16:8'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(selected),
              child: Text('Mantener $selected'),
            ),
          ],
        ),
      );
      if (choice == null) return; // usuario cerró el diálogo — no aplicar nada
      finalProtocol = choice;
      if (choice == selected) warningToAccept = warningKey;
    }

    await ref.read(profileControllerProvider.notifier).updateFastingProtocol(
          currentUser: user,
          protocol: finalProtocol,
          protocolWarningAccepted: warningToAccept,
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
