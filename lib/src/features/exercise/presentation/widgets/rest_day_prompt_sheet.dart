// Propuesta (22-jul, líder de proyecto): ventana flotante post-tour que
// pregunta el día de descanso preferido para el plan semanal de
// ejercicio.
//
// ORIGEN: Carlos vio en un ejemplo de otra app un date-picker de "¿cuándo
// querés empezar?" y propuso algo similar al cerrar el tour. Al revisar
// `WeeklyExercisePlanEngine` (Fase 2, Propuesta módulo Ejercicio
// 2026-07-21) encontramos que el motor NO tiene concepto de "fecha de
// inicio" — es una plantilla semanal que se repite indefinidamente, no
// un calendario con arranque. Lo que SÍ existe y nunca se activó es
// `ExerciseProfile.availableWeekdays`: si el usuario declara EXACTAMENTE
// 6 días disponibles, `WeeklyExercisePlanEngine._restWeekdayFor` infiere
// el 7mo como descanso (ver weekly_exercise_plan_engine.dart líneas
// 143-153). El onboarding siempre manda esa lista vacía ("v1: sin
// restricción declarada"), así que TODO usuario recibe descanso en
// domingo por default sin que el motor use esta señal real. Esta pantalla
// activa esa personalización ya existente en el motor, sin tocarlo.
//
// DISEÑO: en vez de "elegí tus 6 días disponibles" (multi-select, más
// fricción y más superficie de error — el motor solo actúa si son
// EXACTAMENTE 6), se pregunta lo inverso y más simple: "¿qué día
// preferís descansar?" (single-select entre 7). El default preseleccionado
// es Domingo — el mismo default que ya usa el motor — así que si el
// usuario solo toca "Guardar" sin cambiar nada, el comportamiento es
// IDÉNTICO al actual (cero riesgo). "Ahora no" cierra sin escribir nada,
// dejando el perfil como estaba (ver nota en `_save` sobre por qué
// `fetch` + `copyWith` en vez de un `save` a ciegas).
//
// CUÁNDO APARECE: se dispara una sola vez, desde `AppTourOverlay._advance()`
// cuando el usuario completa el ÚLTIMO paso del tour tocando "¡Empezar!"
// (no en "Saltar" — el tour ya solo se muestra una vez por cuenta gracias
// al fix de hoy en app_tour_notifier.dart, así que esta pantalla hereda
// esa misma garantía de "una sola vez" sin necesitar un flag propio).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/exercise/data/exercise_profile_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';

/// ISO weekday (1=lunes..7=domingo) → label corto.
const List<(int, String)> _kWeekdays = [
  (1, 'Lunes'),
  (2, 'Martes'),
  (3, 'Miércoles'),
  (4, 'Jueves'),
  (5, 'Viernes'),
  (6, 'Sábado'),
  (7, 'Domingo'),
];

/// Mismo default que `WeeklyExercisePlanEngine._kDefaultRestWeekday`.
const int _kDefaultRestWeekday = 7;

Future<void> showRestDayPromptSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => const _RestDayPromptSheet(),
  );
}

class _RestDayPromptSheet extends ConsumerStatefulWidget {
  const _RestDayPromptSheet();

  @override
  ConsumerState<_RestDayPromptSheet> createState() =>
      _RestDayPromptSheetState();
}

class _RestDayPromptSheetState extends ConsumerState<_RestDayPromptSheet> {
  int _selectedRestDay = _kDefaultRestWeekday;
  bool _saving = false;

  /// Fetch-then-copyWith-then-save a propósito: `ExerciseProfileRepositoryImpl
  /// .save()` escribe TODOS los campos de `ExerciseProfile.toMap()` (con
  /// `merge: true` a nivel Firestore, pero el mapa en sí no es parcial).
  /// Si construyéramos un `ExerciseProfile` "pelado" solo con
  /// `availableWeekdays`, pisaríamos con defaults (`Sedentario`, `Ninguna`,
  /// etc.) cualquier dato real que el usuario haya declarado en las 3
  /// pantallas de Ejercicio del onboarding. Por eso se lee el perfil
  /// existente primero (o `ExerciseProfile.initial()` si nunca se
  /// inicializó — ver el fix de hoy en `_persistExerciseProfile`, que
  /// ahora puede dejar la cuenta sin ningún documento si el usuario
  /// nunca tocó esas pantallas) y solo se cambia `availableWeekdays`.
  Future<void> _save() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(exerciseProfileRepositoryProvider);
      final existing = await repo.fetch(uid) ?? ExerciseProfile.initial();
      final availableWeekdays = [
        for (final (weekday, _) in _kWeekdays)
          if (weekday != _selectedRestDay) weekday,
      ];
      await repo.save(
        uid,
        existing.copyWith(
          availableWeekdays: availableWeekdays,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // No bloquea el cierre del sheet — mismo criterio que el resto de
      // escrituras "de cortesía" del onboarding (goals, exercise profile):
      // un fallo acá no debe atrapar al usuario en un modal.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
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
              'Antes de arrancar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Qué día preferís que sea tu descanso? Armamos tu plan de '
              'fuerza + cardio alrededor del resto de tu semana.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ..._kWeekdays.map((entry) {
              final (weekday, label) = entry;
              final selected = weekday == _selectedRestDay;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedRestDay = weekday),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.metabolicGreen.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.metabolicGreen
                            : Colors.white10,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected
                              ? AppColors.metabolicGreen
                              : Colors.white.withValues(alpha: 0.35),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.75),
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.metabolicGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed:
                    _saving ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Ahora no',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
