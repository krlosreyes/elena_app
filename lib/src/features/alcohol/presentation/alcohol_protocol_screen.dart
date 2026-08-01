// SPEC-261 / SPEC-261.2: pantalla del Protocolo de Consumo Consciente.
//
// Reducción de daño, sin moralizar. NO es un tablero de controles sueltos:
// es un VIAJE GUIADO por cuatro fases (Antes / Durante / Después /
// Recuperación). La app muestra en cada fase UNA acción principal y avanza
// de forma contextual (registrar el primer trago mueve Antes → Durante).
//
// Todo el estado vive en `consumptionProvider`; esta pantalla lo dibuja y
// dispara acciones. El reloj de metabolización usa un peso de referencia
// (70 kg) en esta versión; personalizarlo con el peso real del usuario es
// un ajuste menor cuando se conecte el perfil.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/alcohol/application/alcohol_recommendation_provider.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_impact.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_recommendation.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_type.dart';

const Color _accent = Color(0xFFB4654A);
const Color _card = Color(0xFF1E293B);
const Color _over = Color(0xFFE879A6);

class AlcoholProtocolScreen extends ConsumerWidget {
  const AlcoholProtocolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(consumptionProvider);
    final notifier = ref.read(consumptionProvider.notifier);

    final body = switch (session.phase) {
      ConsumptionPhase.inactive => _IntroBody(notifier: notifier),
      ConsumptionPhase.antes =>
        _AntesBody(session: session, notifier: notifier),
      ConsumptionPhase.durante =>
        _DuranteBody(session: session, notifier: notifier),
      ConsumptionPhase.despues =>
        _DespuesBody(session: session, notifier: notifier),
      ConsumptionPhase.recuperacion =>
        _RecuperacionBody(session: session, notifier: notifier),
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Consumo consciente',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          if (session.isActive)
            TextButton(
              onPressed: notifier.endProtocol,
              child: Text('Cerrar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SafeArea(
        child: session.isActive
            ? Column(
                children: [
                  _PhaseStepper(phase: session.phase),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Indicador de fase (guía visual del viaje)
// ─────────────────────────────────────────────────────────────────────
class _PhaseStepper extends StatelessWidget {
  const _PhaseStepper({required this.phase});
  final ConsumptionPhase phase;

  static const _labels = ['Antes', 'Durante', 'Después', 'Recup.'];

  int get _index => switch (phase) {
        ConsumptionPhase.inactive => 0,
        ConsumptionPhase.antes => 0,
        ConsumptionPhase.durante => 1,
        ConsumptionPhase.despues => 2,
        ConsumptionPhase.recuperacion => 3,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i <= _index;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        color: active
                            ? _accent
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style: TextStyle(
                    color: active
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    fontWeight: i == _index ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Fase 0 · Intro (protocolo inactivo)
// ─────────────────────────────────────────────────────────────────────
class _IntroBody extends StatelessWidget {
  const _IntroBody({required this.notifier});
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wine_bar, color: _accent, size: 30),
              const SizedBox(height: 12),
              const Text(
                'Vamos a compartir unos tragos 🍻',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Te acompaño en cuatro pasos para que el impacto '
                'metabólico sea el mínimo posible y la recuperación, la máxima.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _phaseTile(
            '1 · Antes', 'Fijar tu meta, tu hora de dormir y prepararte.'),
        _phaseTile('2 · Durante', 'Registrar cada trago, agua 1:1 y espaciar.'),
        _phaseTile('3 · Después', 'Agua + electrolitos y cuidar el sueño.'),
        _phaseTile('4 · Recuperación',
            'Ayuno de recuperación e hidratación al día siguiente.'),
        const SizedBox(height: 24),
        _PrimaryCta(
          label: 'Activar protocolo',
          onPressed: () => notifier.startProtocol(),
        ),
        const SizedBox(height: 16),
        _disclaimer(),
      ],
    );
  }

  Widget _phaseTile(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Fase A · Antes (preparación)
// ─────────────────────────────────────────────────────────────────────
class _AntesBody extends ConsumerWidget {
  const _AntesBody({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = DrinkTypes.byId(session.drinkTypeId);
    final rec = ref.watch(drinkRecommendationProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const _PhaseTitle('Antes de salir', 'Arma tu plan en 30 segundos.'),
        const SizedBox(height: 16),

        // 1) Tipo de trago
        _sectionLabel('¿QUÉ VAS A TOMAR?'),
        _PickerField(
          value: type?.label ?? 'Elegir tipo de trago',
          icon: Icons.local_bar,
          onTap: () => _showDrinkTypePicker(context),
        ),
        if (type != null) ...[
          const SizedBox(height: 6),
          _hint(type.hint),
        ],
        const SizedBox(height: 20),

        // 2) Hora de inicio
        _sectionLabel('¿A QUÉ HORA ARRANCA?'),
        _PickerField(
          value: session.startTime != null
              ? _hhmm(session.startTime!)
              : 'Elegir hora de inicio',
          icon: Icons.schedule,
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: session.startTime != null
                  ? TimeOfDay.fromDateTime(session.startTime!)
                  : TimeOfDay.now(),
              helpText: '¿A qué hora arranca la fiesta?',
            );
            if (picked == null) return;
            final now = DateTime.now();
            notifier.setStartTime(DateTime(
                now.year, now.month, now.day, picked.hour, picked.minute));
          },
        ),
        const SizedBox(height: 20),

        // 3) Agenda de mañana
        _sectionLabel('MAÑANA, ¿QUÉ TIENES?'),
        _ScheduleSelector(session: session, notifier: notifier),
        const SizedBox(height: 20),

        // 4) Plan
        if (rec != null)
          _PlanCard(rec: rec, type: type)
        else
          _hint('Elige el tipo de trago y la hora de inicio para ver tu plan.'),
        const SizedBox(height: 20),

        // 5) Preparación
        _sectionLabel('PREPARACIÓN'),
        _SwitchTile(
          label: 'Me hidraté antes (agua + electrolitos)',
          value: session.hydratedBefore,
          onChanged: notifier.setHydratedBefore,
        ),
        _SwitchTile(
          label: 'Comí proteína / grasa / fibra antes',
          value: session.ateBefore,
          onChanged: notifier.setAteBefore,
        ),
        const SizedBox(height: 24),

        _PrimaryCta(
          label: 'Empezar a registrar',
          onPressed: () {
            if (rec != null) {
              notifier.applyPlan(rec);
            } else {
              notifier.advancePhase();
            }
          },
        ),
        const SizedBox(height: 16),
        _disclaimer(),
      ],
    );
  }

  Future<void> _showDrinkTypePicker(BuildContext context) async {
    final options = DrinkTypes.all;
    var sel = options.indexWhere((o) => o.id == session.drinkTypeId);
    if (sel < 0) sel = 0;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: _card,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () {
                  notifier.setDrinkType(options[sel].id);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Listo',
                    style:
                        TextStyle(color: _accent, fontWeight: FontWeight.w700)),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: sel),
                itemExtent: 40,
                backgroundColor: _card,
                onSelectedItemChanged: (i) => sel = i,
                children: options
                    .map((o) => Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              o.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSelector extends StatelessWidget {
  const _ScheduleSelector({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _choice(
              label: 'Descanso',
              selected: !session.worksTomorrow,
              onTap: () => notifier.setSchedule(worksTomorrow: false),
            ),
            const SizedBox(width: 10),
            _choice(
              label: 'Trabajo',
              selected: session.worksTomorrow,
              onTap: () => notifier.setSchedule(
                  worksTomorrow: true, wakeTime: session.wakeTime),
            ),
          ],
        ),
        if (session.worksTomorrow) ...[
          const SizedBox(height: 10),
          _PickerField(
            value: session.wakeTime != null
                ? '¿Te levantas a las ${_hhmm(session.wakeTime!)}?'
                : '¿A qué hora te levantas?',
            icon: Icons.alarm,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: session.wakeTime != null
                    ? TimeOfDay.fromDateTime(session.wakeTime!)
                    : const TimeOfDay(hour: 7, minute: 0),
                helpText: '¿A qué hora te levantas mañana?',
              );
              if (picked == null) return;
              // Mañana: día siguiente al inicio (o a hoy).
              final base = session.startTime ?? DateTime.now();
              final wake = DateTime(base.year, base.month, base.day,
                      picked.hour, picked.minute)
                  .add(const Duration(days: 1));
              notifier.setSchedule(worksTomorrow: true, wakeTime: wake);
            },
          ),
        ],
      ],
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent.withValues(alpha: 0.20) : _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _accent.withValues(alpha: selected ? 0.6 : 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 1 : 0.7),
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.rec, required this.type});
  final DrinkRecommendation rec;
  final DrinkTypeOption? type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text('Tu plan de esta noche',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.local_bar,
              '${rec.drinks} × ${rec.servingLabel} · una cada ${_spacingText(rec.spacingMinutes)}'),
          _row(Icons.local_drink_outlined,
              '${rec.waterGlasses} ${rec.waterGlasses == 1 ? "vaso" : "vasos"} de agua (1:1) + 500 ml antes'),
          _row(Icons.wine_bar,
              'Una servida = ${rec.servingLabel}. Sin dobles ni "rellenar".'),
          _row(Icons.nightlight_round,
              'Último trago ${_hhmm(rec.lastCall)} · a dormir ${_hhmm(rec.bedtime)}'),
          if (type != null && type!.highCongeners)
            _row(Icons.warning_amber_rounded,
                'Es un destilado oscuro: si puedes, prefiere uno claro (menos resaca)'),
          if (type != null && type!.carbonated)
            _row(Icons.bubble_chart_outlined,
                'Es carbonatado: entra rápido, sórbelo y espacia'),
          const SizedBox(height: 6),
          _row(Icons.restaurant,
              'Come proteína/grasa/fibra antes: baja el pico de alcohol hasta 20–57 %'),
          const SizedBox(height: 8),
          Text(
            rec.tight
                ? 'Tu cuerpo y el tiempo dan para poco: una servida bien '
                    'espaciada es lo que te deja en zona social.'
                : 'Este plan te mantiene en zona social. Pasarte de ahí ya no '
                    'es "una copa más", es emborracharte.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

Widget _hint(String text) => Text(
      text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          height: 1.4),
    );

/// Minutos → texto legible del espaciado, ej. 132 → "2 h 12 min".
String _spacingText(int minutes) => AlcoholMath.formatHours(minutes / 60);

// ─────────────────────────────────────────────────────────────────────
// Fase B · Durante (en vivo)
// ─────────────────────────────────────────────────────────────────────
class _DuranteBody extends StatelessWidget {
  const _DuranteBody({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final grams = session.totalGrams;
    final clearH = AlcoholMath.hoursToMetabolize(grams: grams, weightKg: 70);
    final netCost = AlcoholImpact.netCostForSession(session);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _SummaryCard(
            session: session, grams: grams, clearH: clearH, netCost: netCost),
        const SizedBox(height: 16),
        _LastCallBanner(session: session),
        const SizedBox(height: 20),
        _DrinksList(session: session, notifier: notifier),
        const SizedBox(height: 20),
        _Catalog(notifier: notifier),
        const SizedBox(height: 24),
        _PrimaryCta(
          label: 'Terminé por hoy',
          onPressed: notifier.advancePhase, // Durante → Después
        ),
      ],
    );
  }
}

class _LastCallBanner extends StatelessWidget {
  const _LastCallBanner({required this.session});
  final ConsumptionSession session;

  @override
  Widget build(BuildContext context) {
    final target = session.lastCallTarget;
    if (target == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final remaining = target.difference(now);
    final passed = remaining.isNegative;
    final text = passed
        ? 'Ya pasó tu hora de último trago (${_hhmm(target)}). Cerrar acá cuida tu sueño.'
        : 'Último trago a las ${_hhmm(target)} · faltan ${AlcoholMath.formatHours(remaining.inMinutes / 60)}.';
    final color = passed ? _over : _accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(passed ? Icons.nightlight_round : Icons.timer_outlined,
              color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Fase C · Después (cierre de la noche)
// ─────────────────────────────────────────────────────────────────────
class _DespuesBody extends StatelessWidget {
  const _DespuesBody({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final risk = session.sleepRisk;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const _PhaseTitle('Cierra la noche', 'Dos gestos para dormir mejor.'),
        const SizedBox(height: 16),
        _SleepRiskCard(risk: risk, session: session),
        const SizedBox(height: 16),
        _tip(Icons.local_drink_outlined,
            'Un vaso grande de agua + electrolitos antes de acostarte.'),
        _tip(Icons.watch_later_outlined,
            'Cuanto más tiempo entre el último trago y la cama, mejor tu REM.'),
        const SizedBox(height: 24),
        _PrimaryCta(
          label: 'Buenas noches',
          onPressed: notifier.advancePhase, // Después → Recuperación
        ),
      ],
    );
  }
}

class _SleepRiskCard extends StatelessWidget {
  const _SleepRiskCard({required this.risk, required this.session});
  final SleepRisk risk;
  final ConsumptionSession session;

  @override
  Widget build(BuildContext context) {
    final (label, msg, color) = switch (risk) {
      SleepRisk.none => (
          'Sin datos de sueño',
          'Fija tu hora de dormir la próxima para estimar el impacto en tu sueño.',
          Colors.white24,
        ),
      SleepRisk.low => (
          'Riesgo de sueño: bajo',
          'Tu último trago dejó margen antes de dormir. El alcohol igual altera '
              'el REM, pero le diste tiempo a tu cuerpo.',
          _accent,
        ),
      SleepRisk.high => (
          'Riesgo de sueño: alto',
          'Tu último trago fue muy cerca de dormir. Espera lo posible antes de '
              'acostarte e hidrátate; probablemente notes el sueño más fragmentado.',
          _over,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(msg,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Fase D · Recuperación (día siguiente)
// ─────────────────────────────────────────────────────────────────────
class _RecuperacionBody extends StatelessWidget {
  const _RecuperacionBody({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final netCost = AlcoholImpact.netCostForSession(session);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const _PhaseTitle(
            'Recuperación', 'Hoy tu cuerpo restaura lo que el alcohol frenó.'),
        const SizedBox(height: 16),
        _SwitchTile(
          label: 'Voy a extender mi ayuno de recuperación',
          value: session.recoveryFastPlanned,
          onChanged: notifier.setRecoveryFastPlanned,
        ),
        const SizedBox(height: 8),
        _tip(Icons.self_improvement_outlined,
            'Prioriza hidratación y movimiento ligero. Nada de entrenamiento intenso hoy.'),
        _tip(Icons.eco_outlined,
            'Extender el ayuno ayuda a recuperar autofagia y oxidación de grasa.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            'La noche costó ${AlcoholImpact.label(netCost).toLowerCase()} '
            '(${netCost.toStringAsFixed(0)} pts a tu Score del Día). Lo que hagas '
            'hoy no lo borra, pero sí acelera la vuelta a tu línea de base.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryCta(
          label: 'Cerrar protocolo',
          onPressed: notifier.endProtocol,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Piezas compartidas
// ─────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.session,
    required this.grams,
    required this.clearH,
    required this.netCost,
  });
  final ConsumptionSession session;
  final double grams;
  final double clearH;
  final double netCost;

  @override
  Widget build(BuildContext context) {
    final unidades = session.totalStandardUnits;
    final over = session.budgetExceeded;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('${unidades.toStringAsFixed(1)} UEA',
                  'de ${session.budgetStandardUnits.toStringAsFixed(1)}',
                  color: over ? _over : Colors.white),
              _metric('${grams.toStringAsFixed(0)} g', 'alcohol'),
              _metric(AlcoholMath.formatHours(clearH), 'para volver a cero'),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 12),
          Text(
            'Impacto estimado: ${AlcoholImpact.label(netCost)} '
            '(${netCost.toStringAsFixed(0)} pts)',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            over
                ? 'Vas por encima de tu meta. Sin juzgar: un vaso de agua y baja el ritmo.'
                : 'Vas dentro del plan. Un vaso de agua por trago te mantiene ahí.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}

class _DrinksList extends StatelessWidget {
  const _DrinksList({required this.session, required this.notifier});
  final ConsumptionSession session;
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (session.drinks.isEmpty) {
      return _sectionLabel('AÚN SIN TRAGOS · REGISTRA EL PRIMERO ABAJO');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('LO QUE LLEVAS'),
            TextButton.icon(
              onPressed: notifier.removeLastDrink,
              icon: Icon(Icons.undo_rounded,
                  size: 16, color: Colors.white.withValues(alpha: 0.6)),
              label: Text('Deshacer',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
            ),
          ],
        ),
        ...session.drinks.reversed.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 7, color: _accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  Text('${d.grams.toStringAsFixed(0)} g',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            )),
      ],
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.notifier});
  final ConsumptionNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('REGISTRAR UN TRAGO'),
        for (final cat in DrinkCategory.values) ..._categoryBlock(cat),
      ],
    );
  }

  List<Widget> _categoryBlock(DrinkCategory cat) {
    final items = AlcoholCatalog.byCategory(cat);
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(_categoryLabel(cat),
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => _DrinkChip(
                  item: item,
                  onTap: () => notifier.logDrink(item),
                ))
            .toList(),
      ),
    ];
  }

  static String _categoryLabel(DrinkCategory c) => switch (c) {
        DrinkCategory.cerveza => 'Cervezas',
        DrinkCategory.vino => 'Vinos',
        DrinkCategory.espumanteFortificado => 'Espumantes y fortificados',
        DrinkCategory.destilado => 'Destilados',
        DrinkCategory.aguardienteLatam => 'Aguardientes',
        DrinkCategory.coctel => 'Cócteles',
        DrinkCategory.sinAlcohol => 'Sin / bajo alcohol',
      };
}

class _DrinkChip extends StatelessWidget {
  const _DrinkChip({required this.item, required this.onTap});
  final AlcoholCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: _accent),
            const SizedBox(width: 6),
            Text(item.name,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 6),
            Text('${item.standardUnitsFor().toStringAsFixed(1)} UEA',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PhaseTitle extends StatelessWidget {
  const _PhaseTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }
}

Widget _tip(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.45)),
        ),
      ],
    ),
  );
}

Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );

Widget _disclaimer() => Text(
      'Esto no es consejo médico. La estimación de alcoholemia es orientativa '
      'y nunca debe usarse para decidir si conducir.',
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          height: 1.4),
    );

String _hhmm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
