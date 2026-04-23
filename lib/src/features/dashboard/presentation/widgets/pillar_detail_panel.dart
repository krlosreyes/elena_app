// SPEC-19: Panel de detalle interactivo por pilar
//
// Recibe [selectedIndex] y renderiza el panel correspondiente.
// Cada panel muestra: progreso en tiempo real, acción de registro
// y opción de corrección de entrada errónea.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/constants/pillar_constants.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/shared/providers/sleep_provider.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_prompt_sheet.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
import 'package:elena_app/src/features/nutrition/presentation/fasting_prompt_sheet.dart';
import 'package:elena_app/src/features/nutrition/presentation/add_past_meal_sheet.dart';

class PillarDetailPanel extends ConsumerWidget {
  const PillarDetailPanel({
    super.key,
    required this.selectedIndex,
    required this.user,
  });

  final int selectedIndex;
  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(selectedIndex),
        child: switch (selectedIndex) {
          0 => _FastingPanel(user: user),
          1 => _SleepPanel(user: user),
          2 => _HydrationPanel(),
          3 => _ExercisePanel(user: user),
          4 => _NutritionPanel(),
          _ => _FastingPanel(user: user),
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPONENTES COMPARTIDOS
// ═══════════════════════════════════════════════════════════════════════════

/// Barra de progreso con label
Widget _progressBar(double progress, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${(progress * 100).toInt()}% completado',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withOpacity(0.4),
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// Botón de acción principal
Widget _primaryButton({
  required String label,
  required Color color,
  required VoidCallback? onTap,
  IconData icon = Icons.add_circle_outline_rounded,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        elevation: 0,
      ),
    ),
  );
}

/// Botón de corrección (secundario, discreto)
Widget _correctionButton({
  required String label,
  required VoidCallback? onTap,
  IconData icon = Icons.edit_outlined,
}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.5),
        side: BorderSide(color: Colors.white.withOpacity(0.12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Contenedor base de cada panel
Widget _panelShell({required List<Widget> children}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

/// Chip de estado (fase, zona, label)
Widget _statusChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 0.6,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 0 · AYUNO CONSCIENTE
// ═══════════════════════════════════════════════════════════════════════════

class _FastingPanel extends ConsumerStatefulWidget {
  const _FastingPanel({required this.user});
  final UserModel user;

  @override
  ConsumerState<_FastingPanel> createState() => _FastingPanelState();
}

class _FastingPanelState extends ConsumerState<_FastingPanel> {
  static const _color = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final fs = ref.watch(fastingProvider);
    final notifier = ref.read(fastingProvider.notifier);

    final phaseLabel = _phaseLabel(fs.phase);
    final nextPhaseLabel = _nextPhaseLabel(fs);
    final benefits = _benefitsFor(fs.phase, widget.user.pathologies);

    String twoD(int n) => n.toString().padLeft(2, '0');
    final timer = fs.isActive
        ? '${twoD(fs.duration.inHours)}:${twoD(fs.duration.inMinutes.remainder(60))}:${twoD(fs.duration.inSeconds.remainder(60))}'
        : '--:--:--';

    return _panelShell(children: [
      // ── Header ─────────────────────────────────────────────────────────
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            PillarConstants.pilarAyuno,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          _statusChip(phaseLabel, _color),
        ],
      ),
      const SizedBox(height: 16),

      // ── Timer + protocolo ───────────────────────────────────────────────
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timer,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _color,
              fontFamily: 'monospace',
              height: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              fs.fastingProtocol,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // ── Progreso ────────────────────────────────────────────────────────
      _progressBar(fs.progressPercentage, _color),
      const SizedBox(height: 12),

      // ── Siguiente etapa ─────────────────────────────────────────────────
      if (nextPhaseLabel.isNotEmpty) ...[
        Row(
          children: [
            Icon(Icons.arrow_forward_rounded, size: 12, color: _color.withOpacity(0.7)),
            const SizedBox(width: 4),
            Text(
              nextPhaseLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],

      // ── Beneficios desbloqueados ────────────────────────────────────────
      if (benefits.isNotEmpty) ...[
        Text(
          fs.isActive ? 'BENEFICIOS ACTIVOS' : 'BENEFICIOS AL INICIAR',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        ...benefits.map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓ ', style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w900)),
              Expanded(
                child: Text(
                  b,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65), height: 1.3),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 14),
      ],

      // ── Acción principal ────────────────────────────────────────────────
      fs.isSaving
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : _primaryButton(
              label: fs.isActive ? 'Detener Ayuno' : 'Iniciar Ayuno',
              color: fs.isActive ? Colors.redAccent : _color,
              icon: fs.isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
              onTap: () => fs.isActive ? notifier.stopFasting() : notifier.startFasting(),
            ),
      const SizedBox(height: 8),

      // ── Corrección: editar hora de inicio ──────────────────────────────
      _correctionButton(
        label: 'Corregir hora de inicio',
        icon: Icons.schedule_rounded,
        onTap: () => _pickCorrectStartTime(context, notifier, fs),
      ),
    ]);
  }

  Future<void> _pickCorrectStartTime(
    BuildContext context,
    FastingNotifier notifier,
    FastingState fs,
  ) async {
    final now = DateTime.now();
    
    // 1. Seleccionar Fecha
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: fs.startTime ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: 'FECHA DE INICIO REAL',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _color),
          dialogBackgroundColor: const Color(0xFF1E293B),
        ),
        child: child!,
      ),
    );
    
    if (pickedDate == null) return;

    // 2. Seleccionar Hora
    final initialTime = fs.startTime != null
        ? TimeOfDay.fromDateTime(fs.startTime!)
        : TimeOfDay.fromDateTime(now);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'HORA DE INICIO REAL',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: _color),
          dialogBackgroundColor: const Color(0xFF1E293B),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final finalTime = DateTime(
      pickedDate.year, 
      pickedDate.month, 
      pickedDate.day, 
      pickedTime.hour, 
      pickedTime.minute,
    );

    await notifier.startFastingManual(finalTime);
  }


  String _phaseLabel(FastingPhase phase) => switch (phase) {
    FastingPhase.postAbsorption => 'Descenso de Insulina',
    FastingPhase.transition     => 'Gluconeogénesis',
    FastingPhase.fatBurning     => 'Quema de Grasa',
    FastingPhase.autophagy      => 'Autofagia',
    FastingPhase.survival       => 'Regeneración',
    _                           => 'En espera',
  };

  String _nextPhaseLabel(FastingState fs) {
    if (!fs.isActive) return '';
    final h = fs.duration.inHours;
    final rem = fs.timeRemainingForNextMilestone;
    final mm = rem.inMinutes.remainder(60);
    final hh = rem.inHours;
    final t = hh > 0 ? '${hh}h ${mm}m' : '${mm}m';
    if (h < 12) return 'Gluconeogénesis en $t';
    if (h < 18) return 'Cetosis activa en $t';
    if (h < 24) return 'Autofagia en $t';
    return 'Regeneración celular activa';
  }

  List<String> _benefitsFor(FastingPhase phase, List<String> pathologies) {
    final hasPrediabetes = pathologies.any((p) => p.toLowerCase().contains('prediab') || p.toLowerCase().contains('insulina'));
    final hasNAFLD = pathologies.any((p) => p.toLowerCase().contains('hígado') || p.toLowerCase().contains('higado') || p.toLowerCase().contains('graso'));

    if (phase == FastingPhase.none) {
      return [
        if (hasPrediabetes) 'Reduce resistencia a la insulina desde la 1ª hora',
        if (hasNAFLD) 'Inicia oxidación de grasa hepática en fase postabsorción',
        'Regula glucosa en ayunas y mejora sensibilidad metabólica',
      ];
    }
    if (phase == FastingPhase.postAbsorption) {
      return [
        if (hasPrediabetes) 'Insulina descendiendo — ventana óptima para sensibilidad',
        if (hasNAFLD) 'El hígado empieza a consumir glucógeno propio',
        'Glucagón elevado: movilización de reservas energéticas',
      ];
    }
    if (phase == FastingPhase.transition) {
      return [
        if (hasPrediabetes) 'Gluconeogénesis activa — insulina en mínimo diario',
        if (hasNAFLD) 'Lipólisis hepática iniciada — reducción activa de grasa visceral',
        'Cortisol matutino optimizado para regeneración muscular',
      ];
    }
    if (phase == FastingPhase.fatBurning) {
      return [
        if (hasPrediabetes) 'Cetosis nutricional — cuerpos cetónicos mejoran función pancreática',
        if (hasNAFLD) 'Oxidación máxima de ácidos grasos hepáticos',
        'HGH elevada: preservación de masa magra mientras se quema grasa',
      ];
    }
    return [
      if (hasPrediabetes) 'Autofagia regenera células beta del páncreas',
      if (hasNAFLD) 'Reciclaje celular hepático en máxima expresión',
      'Reducción de inflamación sistémica',
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1 · SUEÑO (SOPORTE METABÓLICO)
// ═══════════════════════════════════════════════════════════════════════════

class _SleepPanel extends ConsumerStatefulWidget {
  const _SleepPanel({required this.user});
  final UserModel user;

  @override
  ConsumerState<_SleepPanel> createState() => _SleepPanelState();
}

class _SleepPanelState extends ConsumerState<_SleepPanel> {
  static const _color = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    final ss = ref.watch(globalSleepProvider);
    final notifier = ref.read(globalSleepProvider.notifier);

    final log = ss.lastLog;
    final hours = log?.duration.inHours ?? 0;
    final mins  = log?.duration.inMinutes.remainder(60) ?? 0;
    final progress = (hours / 9.0).clamp(0.0, 1.0);

    String _fmt(DateTime dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    void openSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SleepInputSheet(),
      );
    }

    // SPEC-22: Mostrar prompt si debe mostrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ss.shouldShowSleepPrompt && mounted) {
        notifier.clearSleepPrompt();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SleepPromptSheet(),
        );
      }
    });

    return _panelShell(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(PillarConstants.pilarSoporte,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          _statusChip(PillarConstants.trackingLabelSueno, _color),
        ],
      ),
      const SizedBox(height: 16),

      // ── Datos del registro o predicción de hora ─────────────────────────
      log != null
          ? Row(
              children: [
                _stat('Dormiste', '${hours}h ${mins}m', _color),
                const SizedBox(width: 24),
                _stat('Acostado', _fmt(log.fellAsleep), Colors.white.withOpacity(0.55)),
                const SizedBox(width: 24),
                _stat('Despertaste', _fmt(log.wokeUp), Colors.white.withOpacity(0.55)),
              ],
            )
          : Row(
              children: [
                _stat('Hora de dormir', _fmt(widget.user.profile.sleepTime), _color),
                const SizedBox(width: 24),
                _stat('Despertar', _fmt(widget.user.profile.wakeUpTime), Colors.white.withOpacity(0.55)),
              ],
            ),
      const SizedBox(height: 14),

      // ── Meta 7-9h ──────────────────────────────────────────────────────
      Row(children: [
        Icon(Icons.flag_outlined, size: 12, color: _color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text('Meta: 7–9 horas', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
      ]),
      const SizedBox(height: 8),
      _progressBar(progress, _color),

      // ── Insight personalizado ───────────────────────────────────────────
      if (hours > 0) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            hours >= 7
                ? '✓ Sueño reparador — GH pulsátil activa durante ciclos REM'
                : hours >= 5
                    ? 'Sueño insuficiente — cortisol elevado, resistencia a insulina +38%'
                    : 'Privación de sueño — impacto directo en grelina y control de glucosa',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
          ),
        ),
      ] else ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Tu ciclo circadiano está configurado para ${_fmt(widget.user.profile.sleepTime)} — ${_fmt(widget.user.profile.wakeUpTime)}. Registra tu sueño para optimizar tus métricas metabólicas.',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
          ),
        ),
      ],
      const SizedBox(height: 16),

      ss.isSaving
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : _primaryButton(
              label: log == null ? 'Registrar Sueño' : 'Actualizar Registro',
              color: _color,
              icon: Icons.nightlight_round,
              onTap: openSheet,
            ),
      const SizedBox(height: 8),

      // ── Corrección ─────────────────────────────────────────────────────
      if (log != null)
        _correctionButton(
          label: 'Eliminar registro y volver a registrar',
          icon: Icons.delete_outline_rounded,
          onTap: () async {
            await notifier.clearTodayLog();
            if (context.mounted) openSheet();
          },
        ),
    ]);
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · HIDRATACIÓN (SOPORTE METABÓLICO)
// ═══════════════════════════════════════════════════════════════════════════

class _HydrationPanel extends ConsumerWidget {
  const _HydrationPanel();

  static const _color = Color(0xFF38BDF8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hs = ref.watch(hydrationProvider);
    final notifier = ref.read(hydrationProvider.notifier);

    return _panelShell(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(PillarConstants.pilarSoporte,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          _statusChip(PillarConstants.trackingLabelHidratacion, _color),
        ],
      ),
      const SizedBox(height: 16),

      // ── Litros actuales ─────────────────────────────────────────────────
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${hs.currentFormatted} L',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _color, height: 1.0),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '/ ${hs.goalFormatted} L',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _progressBar(hs.progressPercentage, _color),

      // ── Insight ─────────────────────────────────────────────────────────
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          hs.isGoalReached
              ? '✓ Meta alcanzada — transporte de nutrientes y termorregulación óptimos'
              : 'Cada 250ml mejora el flujo linfático y la eliminación de metabolitos',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
        ),
      ),
      const SizedBox(height: 16),

      // ── Botones de registro ─────────────────────────────────────────────
      Row(
        children: [
          Expanded(
            child: _waterButton(
              label: '+250 ml',
              color: _color,
              onTap: hs.isSaving ? null : () => notifier.addWater(0.25),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _waterButton(
              label: '+500 ml',
              color: _color,
              onTap: hs.isSaving ? null : () => notifier.addWater(0.5),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      // ── Corrección ─────────────────────────────────────────────────────
      _correctionButton(
        label: 'Descontar último vaso (−250 ml)',
        icon: Icons.remove_circle_outline_rounded,
        onTap: hs.currentAmountLiters <= 0 || hs.isSaving
            ? null
            : () => notifier.removeLastEntry(),
      ),
    ]);
  }

  Widget _waterButton({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · EJERCICIO (SARCOPENIA & RESISTENCIA)
// ═══════════════════════════════════════════════════════════════════════════

class _ExercisePanel extends ConsumerWidget {
  const _ExercisePanel({required this.user});
  final UserModel user;

  static const _color = Color(0xFF2DD4BF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final es = ref.watch(exerciseProvider);
    final notifier = ref.read(exerciseProvider.notifier);
    final goal = user.exerciseGoalMinutes;
    final progress = (es.todayMinutes / goal.clamp(1, 180)).clamp(0.0, 1.0);

    void openSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ExerciseInputSheet(),
      );
    }

    return _panelShell(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(PillarConstants.pilarEjercicio,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          _statusChip(es.todayMinutes > 0 ? 'ACTIVO' : 'SIN REGISTRO', _color),
        ],
      ),
      const SizedBox(height: 16),

      // ── Minutos actuales ────────────────────────────────────────────────
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${es.todayMinutes} min',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _color, height: 1.0),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '/ $goal min meta',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _progressBar(progress, _color),

      // ── Insight ─────────────────────────────────────────────────────────
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          es.todayMinutes >= goal
              ? '✓ Meta cumplida — síntesis proteica muscular activa 24-48h post sesión'
              : es.todayMinutes >= 20
                  ? 'Activación AMPK — sensibilidad a insulina mejorada post ejercicio'
                  : '30 min activan GLUT4 muscular — eliminación directa de glucosa sin insulina',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
        ),
      ),
      const SizedBox(height: 16),

      es.isSaving
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          : _primaryButton(
              label: es.todayMinutes > 0 ? 'Agregar Sesión' : 'Registrar Ejercicio',
              color: _color,
              icon: Icons.fitness_center_rounded,
              onTap: openSheet,
            ),
      const SizedBox(height: 8),

      // ── Corrección ─────────────────────────────────────────────────────
      if (es.todayMinutes > 0)
        _correctionButton(
          label: 'Eliminar última sesión',
          icon: Icons.delete_outline_rounded,
          onTap: es.isSaving ? null : () => notifier.deleteLastSession(),
        ),

      if (es.error != null) ...[
        const SizedBox(height: 8),
        Text(
          es.error!,
          style: const TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      ],
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · NUTRICIÓN CIENTÍFICA
// ═══════════════════════════════════════════════════════════════════════════

class _NutritionPanel extends ConsumerStatefulWidget {
  const _NutritionPanel();

  @override
  ConsumerState<_NutritionPanel> createState() => _NutritionPanelState();
}

class _NutritionPanelState extends ConsumerState<_NutritionPanel> {
  static const _color = Color(0xFFFB923C);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ns = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final fastingActive = ref.watch(fastingProvider).isActive;

    final windowPct = (ns.windowAdherence * 100).toInt();

    // SPEC-21: Mostrar prompt si es la última comida
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ns.shouldShowFastingPrompt && mounted) {
        notifier.clearFastingPrompt();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const FastingPromptSheet(),
        );
      }
    });

    return _panelShell(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(PillarConstants.pilarNutricion,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
          _statusChip('${ns.mealsLoggedToday}/${ns.targetMeals} comidas', _color),
        ],
      ),
      const SizedBox(height: 16),

      // ── Progreso de comidas ─────────────────────────────────────────────
      _progressBar(ns.progressPercentage, _color),
      const SizedBox(height: 12),

      // ── Stats con SPEC-21: Timer countdown ────────────────────────────
      Row(
        children: [
          _stat('Próxima', ns.nextMealLabel, _color),
          const SizedBox(width: 24),
          if (ns.nextMealCountdown != null)
            _stat(
              'En',
              _formatDuration(ns.nextMealCountdown!),
              _color,
            )
          else
            _stat('Ventana', '$windowPct%', Colors.white.withOpacity(0.55)),
          const SizedBox(width: 24),
          _stat('Score nutricional', '${(ns.nutritionScore * 100).toInt()}', Colors.white.withOpacity(0.55)),
        ],
      ),
      const SizedBox(height: 12),

      // ── Insight ─────────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          windowPct >= 80
              ? '✓ Comidas dentro de ventana circadiana — alineación con ritmo metabólico óptima'
              : windowPct > 0
                  ? 'Mejora el timing de comidas para maximizar el IMR en el bloque Conducta'
                  : 'Registra tus comidas para calcular la adherencia circadiana',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
        ),
      ),
      const SizedBox(height: 16),

      // ── Aviso de ayuno activo ───────────────────────────────────────────
      if (fastingActive) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Registro bloqueado — ayuno activo. Detén el ayuno para registrar comidas.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent.withOpacity(0.85),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ] else ...[
        ns.isSaving
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            : _primaryButton(
                label: 'Registrar ${ns.nextMealLabel}',
                color: _color,
                icon: Icons.restaurant_menu_rounded,
                onTap: () => notifier.logMeal(),
              ),
        const SizedBox(height: 8),

        // ── Registrar comida pasada (SPEC-26: Historial) ──────────────────
        _correctionButton(
          label: 'Registrar comida pasada',
          icon: Icons.history_rounded,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddPastMealSheet(),
            );
          },
        ),
        const SizedBox(height: 8),

        // ── Corrección ───────────────────────────────────────────────────
        if (ns.mealsLoggedToday > 0)
          _correctionButton(
            label: 'Deshacer última comida registrada',
            icon: Icons.undo_rounded,
            onTap: () async => await notifier.removeLastMeal(),
          ),
      ],
    ]);
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.35), fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  /// Formatea Duration a "HH:MM" legible
  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
