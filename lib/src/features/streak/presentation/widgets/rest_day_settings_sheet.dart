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
    // `save` es fire-and-forget (offline-first): no se espera a la red
    // para confirmar una preferencia. El stream de Firestore devuelve el
    // valor y la racha se recalcula sola vía el listener de StreakNotifier.
    await ref.read(restDayPolicyRepositoryProvider).save(uid, next);
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
            const _FloorNotice(),
          ],
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
