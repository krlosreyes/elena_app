// Ajustes del día de descanso planificado (2026-07-28).
//
// Mismo lenguaje visual que exercise/presentation/widgets/
// rest_day_prompt_sheet.dart y glucose/.../glucose_protocol_settings_sheet.dart.
//
// NO reutiliza el descanso de ejercicio pese al parecido: son dos cosas
// distintas. "Hoy no entrenas" no es lo mismo que "hoy no se te exige el
// protocolo completo". Aquí sí se OFRECE alinearlos, porque para la
// mayoría van a coincidir, pero el dato es independiente — ver la nota en
// rest_day_policy_repository.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/data/rest_day_policy_repository.dart';
import 'package:elena_app/src/features/streak/domain/rest_day_policy.dart';

const List<(int, String)> _kWeekdays = [
  (1, 'Lunes'),
  (2, 'Martes'),
  (3, 'Miércoles'),
  (4, 'Jueves'),
  (5, 'Viernes'),
  (6, 'Sábado'),
  (7, 'Domingo'),
];

const Color _kAmber = Color(0xFFF59E0B);
const Color _kSurface = Color(0xFF0F172A);

Future<void> showRestDaySettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RestDaySettingsSheet(),
  );
}

class _RestDaySettingsSheet extends ConsumerStatefulWidget {
  const _RestDaySettingsSheet();

  @override
  ConsumerState<_RestDaySettingsSheet> createState() =>
      _RestDaySettingsSheetState();
}

class _RestDaySettingsSheetState extends ConsumerState<_RestDaySettingsSheet> {
  int? _selected;
  bool _initialized = false;

  Future<void> _save(RestDayPolicy next) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    // Poda en cada escritura: sin esto `movedDates` crecería sin límite,
    // una entrada por cada semana que el usuario mueva, para siempre.
    // Este es el único punto por el que pasan todas las escrituras, así
    // que es donde toca.
    //
    // El corte son 60 días, holgadamente más que los 30 de historial que
    // mira la racha. Podar justo en el borde arriesgaría descartar una
    // fecha que el histórico todavía necesita para no pintar un descanso
    // como día perdido.
    final podada = next.pruneBefore(
      DateTime.now().subtract(const Duration(days: 60)),
    );

    // `save` es fire-and-forget (offline-first): no se espera a la red
    // para confirmar una preferencia. El stream de Firestore devuelve el
    // valor y la racha se recalcula sola vía el listener de StreakNotifier.
    await ref.read(restDayPolicyRepositoryProvider).save(uid, podada);
  }

  @override
  Widget build(BuildContext context) {
    final policy =
        ref.watch(restDayPolicyProvider).valueOrNull ?? RestDayPolicy.disabled;

    // Primera lectura: sembrar la selección con lo ya guardado. Después
    // manda el estado local, para que tocar una opción se sienta
    // inmediato y no espere al round-trip de Firestore.
    if (!_initialized) {
      _selected = policy.weeklyRestWeekday;
      _initialized = true;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu día de descanso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Un día a la semana en el que no se te exige el protocolo '
              'completo y tu racha sigue igual. No gasta reserva: '
              'descansar es parte del plan, no un fallo que perdonamos.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ..._kWeekdays.map((entry) {
              final (weekday, label) = entry;
              final selected = weekday == _selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  label: label,
                  selected: selected,
                  onTap: () {
                    setState(() => _selected = weekday);
                    _save(policy.copyWith(weeklyRestWeekday: weekday));
                  },
                ),
              );
            }),
            const SizedBox(height: 4),
            _OptionTile(
              label: 'Sin día de descanso',
              subtitle: 'Prefiero que se me exija todos los días',
              selected: _selected == null,
              onTap: () {
                setState(() => _selected = null);
                _save(policy.copyWith(clearWeekly: true));
              },
            ),
            const SizedBox(height: 24),
            _MoveThisWeekSection(policy: policy, onSave: _save),
            const SizedBox(height: 16),
            const _FloorNotice(),
          ],
        ),
      ),
    );
  }
}

/// Mover el descanso de UNA semana sin cambiar el día fijo (28-jul).
///
/// El caso que lo motiva: tu descanso es el domingo y esta semana la cena
/// con amigos cae el jueves. Sin esto, la única salida sería cambiar el
/// día fijo y acordarse de devolverlo — que nadie hace.
///
/// Solo aparece si hay un descanso configurado Y quedan días futuros en
/// esa semana. La lista de candidatos sale de
/// `RestDayPolicy.movableDatesInWeekOf`, no de aritmética local: si la
/// pantalla construyera su propia lista podría ofrecer un día que
/// `declare` rechaza en silencio, y el usuario tocaría sin que pasara
/// nada.
class _MoveThisWeekSection extends ConsumerWidget {
  final RestDayPolicy policy;
  final Future<void> Function(RestDayPolicy) onSave;

  const _MoveThisWeekSection({required this.policy, required this.onSave});

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// "jue 30 jul" — día de la semana + fecha, porque el usuario piensa en
  /// "el jueves" pero necesita confirmar de qué jueves hablamos.
  static String _etiqueta(String dateKey) {
    final d = DateTime.parse(dateKey);
    final dia = _kWeekdays[d.weekday - 1].$2.substring(0, 3).toLowerCase();
    return '$dia ${d.day} ${_meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El próximo descanso ya lo calcula StreakNotifier — no se recalcula
    // aquí para que no puedan divergir.
    final nextRest = ref.watch(streakProvider.select((s) => s.nextRestDate));
    if (nextRest == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final candidatos = policy
        .movableDatesInWeekOf(DateTime.parse(nextRest), now: now)
        .where((k) => k != nextRest)
        .toList();

    final movida = policy.isMovedWeekOf(nextRest);
    if (candidatos.isEmpty && !movida) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat_rounded,
                  size: 16, color: _kAmber.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mover el de esta semana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            movida
                ? 'Esta semana descansas el ${_etiqueta(nextRest)}.'
                : 'Tu próximo descanso es el ${_etiqueta(nextRest)}. Si esta '
                    'semana te viene mejor otro día, cámbialo solo por esta vez.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if (candidatos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final fecha in candidatos)
                  _DateChip(
                    label: _etiqueta(fecha),
                    onTap: () => onSave(policy.declare(fecha, now: now)),
                  ),
              ],
            ),
          ],
          if (movida) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => onSave(policy.cancelMoveForWeekOf(nextRest)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Volver a mi día habitual',
                style: TextStyle(
                  color: _kAmber.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Solo puedes moverlo a un día que todavía no llegó: es un plan, '
            'no un comodín de última hora.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kAmber.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _kAmber.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _kAmber.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? _kAmber : Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El suelo, dicho antes de que haga falta.
///
/// Va aquí y no en un aviso posterior a propósito: si el usuario se entera
/// del requisito el día que lo incumple, el mecanismo ya falló. La
/// protección que no se conoce de antemano no ahorra ninguna ansiedad —
/// es la lección más transferible del diseño de Duolingo.
class _FloorNotice extends StatelessWidget {
  const _FloorNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round,
                  size: 16, color: _kAmber.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              const Text(
                'Qué se te pide ese día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Solo dormir y beber agua. Nada de ayuno, ejercicio ni '
            'registro de comidas.\n\n'
            'Son los dos pilares que no exigen disciplina y son justo los '
            'que sostienen la recuperación. Descansar es eso: bajar el '
            'ritmo, no desaparecer.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Si ese día tampoco duermes ni te hidratas, entra tu reserva '
            'de racha si tienes alguna. Nunca te quedas sin red.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
