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
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_countdown_panel.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/new_cycle_meals_warning_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/features/streak/domain/fasting_symptom_log.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class FastingConsciousnessCard extends ConsumerWidget {
  const FastingConsciousnessCard({super.key, required this.state});

  final FastingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rediseño Hoy (2026-10-30): esta card es la ACCIÓN PRINCIPAL de la
    // pantalla Hoy. Dos estados:
    //   - Sin ayuno: "Tu ayuno empieza a las …" + Iniciar ayuno.
    //   - Con ayuno: anillo con el tiempo transcurrido + cuánto falta.
    // Se quitaron los "beneficios" (eran promesas médicas), el hito
    // siguiente y la línea de tiempo. Toda la lógica de botones, diálogos
    // y pickers se mantiene igual.
    final isActive = state.isActive;
    const accent = AppColors.metabolicGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isActive
          ? _buildActive(context, ref, accent)
          : _buildIdle(context, ref, accent),
    );
  }

  /// Hora en formato "5:30 p. m.".
  static String _hora12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final suf = t.hour < 12 ? 'a. m.' : 'p. m.';
    return '$h:$m $suf';
  }

  /// Próximo inicio de ayuno según la última comida del perfil.
  DateTime? _nextFastingTime(WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).value;
    final lastMeal = user?.profile.lastMealGoal;
    if (lastMeal == null) return null;
    final now = DateTime.now();
    var candidate =
        DateTime(now.year, now.month, now.day, lastMeal.hour, lastMeal.minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Widget _buildIdle(BuildContext context, WidgetRef ref, Color accent) {
    final next = _nextFastingTime(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VENTANA DE COMIDA',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next != null
                        ? 'Tu ayuno empieza a las ${_hora12(next)}'
                        : 'Listo para iniciar tu ayuno',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.nightlight_outlined, color: accent, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildProtocolChip(
              context: context,
              ref: ref,
              protocol: state.fastingProtocol,
              isActive: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'cierras la cocina y descansas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildFastingPrimaryButton(
          context: context,
          ref: ref,
          state: state,
          isActive: false,
          accent: accent,
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: state.isSaving
                ? null
                : () => _showOngoingFastPicker(context, ref, state),
            child: Text(
              '¿Ya venías ayunando? Registra la hora',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActive(BuildContext context, WidgetRef ref, Color accent) {
    // Rediseño ayuno (2026-11-01): cuenta regresiva HH:MM:SS + barra por
    // etapas que avanza de ámbar a verde (FastingCountdownPanel).
    final start = state.startTime;
    return Column(
      children: [
        if (start != null)
          FastingCountdownPanel(
            startTime: start,
            targetHours: state.targetHours,
          ),
        if (start != null) _buildEatingWindowAdvisory(state),
        const SizedBox(height: 18),
        _buildFastingPrimaryButton(
          context: context,
          ref: ref,
          state: state,
          isActive: true,
          accent: accent,
        ),
        TextButton(
          onPressed: state.isSaving
              ? null
              : () => _showCorrectStartTimePicker(context, ref, state),
          child: Text(
            'Corregir hora de inicio',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

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

    // Rediseño Hoy (2026-10-30): con el ayuno en curso el botón es
    // secundario (fondo tenue, texto verde); sin ayuno, verde sólido.
    final Color bgColor =
        isActive ? Colors.white.withValues(alpha: 0.06) : accent;
    final Color fgColor = isActive ? accent : const Color(0xFF0B1020);

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
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: fgColor,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow_rounded,
                color: fgColor,
                size: 22,
              ),
        label: Text(
          isActive
              ? 'Terminar ayuno'
              : (completedToday ? 'Iniciar nuevo ayuno' : 'Iniciar ayuno'),
          style: TextStyle(
            color: fgColor,
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
    final DateTime hardEarliest = now.subtract(const Duration(days: 7));
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
    if (now.difference(finalDateTime) > const Duration(days: 7)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La corrección no puede ser de hace más de 7 días.',
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

  /// SPEC-260 (2026-07-30): picker para registrar un ayuno que YA venía en
  /// curso (el usuario olvidó darle "Iniciar" al empezar). Elige fecha +
  /// hora pasadas y las envía a `registerOngoingFast`, que ancla el Día
  /// Metabólico a esa hora SIN resetear los otros pilares.
  ///
  /// Se diferencia de `_showCorrectStartTimePicker` en que aplica al
  /// estado INACTIVO y no clampa contra el target: un ayuno olvidado pudo
  /// llevar muchas horas y es legítimo registrarlo así (la guarda amplia es
  /// 7 días atrás, igual que en la corrección y en el inicio manual).
  Future<void> _showOngoingFastPicker(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime earliest = now.subtract(const Duration(days: 7));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
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
      initialTime: TimeOfDay.fromDateTime(now),
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
    if (now.difference(finalDateTime) > const Duration(days: 7)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El inicio no puede ser de hace más de 7 días.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await ref.read(fastingProvider.notifier).registerOngoingFast(finalDateTime);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ayuno registrado. Tu avance de los demás pilares se mantiene.',
        ),
        backgroundColor: AppColors.metabolicGreen,
      ),
    );
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
