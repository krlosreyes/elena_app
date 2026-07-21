// Propuesta módulo Ejercicio (2026-07-21) — pantalla de detalle para
// que un usuario YA EXISTENTE configure (o edite) su ExerciseProfile.
// Mismo formulario que el paso 5 del onboarding
// (onboarding_screen.dart._buildStepExerciseHabits), reimplementado acá
// porque ese paso vive como métodos privados de _OnboardingScreenState
// — extraerlo a un widget compartido hoy hubiera significado tocar de
// nuevo un archivo de 2000+ líneas ya delicado, sin poder compilar para
// verificar el refactor. Se prefirió una duplicación pequeña y
// contenida (un solo archivo, ~250 líneas) a ese riesgo.
//
// A diferencia del onboarding (que persiste solo al final, junto con
// todo lo demás), acá cada guardado es independiente — el usuario ya
// tiene cuenta activa, así que "Guardar" escribe de inmediato.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/exercise/application/exercise_profile_providers.dart';
import 'package:elena_app/src/features/exercise/data/exercise_profile_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';

class ExerciseHabitsDetailScreen extends ConsumerWidget {
  const ExerciseHabitsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(exerciseProfileStreamProvider);

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
          'Hábitos de ejercicio',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => _Body(initial: profile ?? ExerciseProfile.initial()),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.initial});
  final ExerciseProfile initial;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late ExerciseFrequencyLevel _level;
  late ExerciseExperienceLevel _experience;
  late ExerciseEquipment _equipment;
  late Set<ExercisePreferenceTag> _liked;
  late Set<InjuryTag> _injuries;
  late TextEditingController _injuryNotesController;
  late BodyCompositionGoal _goal;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _level = p.currentLevel;
    _experience = p.strengthExperience;
    _equipment = p.equipment;
    _liked = p.likedActivities.toSet();
    _injuries = p.injuries.toSet();
    _injuryNotesController = TextEditingController(text: p.injuryNotes);
    _goal = p.goal;
  }

  @override
  void dispose() {
    _injuryNotesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null || uid.isEmpty) return;

    setState(() => _isSaving = true);
    final profile = ExerciseProfile(
      currentLevel: _level,
      strengthExperience: _experience,
      equipment: _equipment,
      likedActivities: _liked.toList(),
      availableWeekdays: widget.initial.availableWeekdays,
      injuries: _injuries.toList(),
      injuryNotes: _injuryNotesController.text.trim(),
      goal: _goal,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(exerciseProfileRepositoryProvider).save(uid, profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu plan se actualizará con estos hábitos'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No pudimos guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text(
            widget.initial.isInitial
                ? 'Con esto Elena arma tu plan semanal de fuerza + cardio '
                    '— ajustado a lo que ya haces, no a lo que "deberías" '
                    'hacer.'
                : 'Actualiza esto cuando cambie tu rutina, tu equipo '
                    'disponible o tus objetivos — tu plan se recalcula '
                    'automáticamente.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('NIVEL ACTUAL'),
          _chipGroup<ExerciseFrequencyLevel>(
            options: ExerciseFrequencyLevel.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _level == v,
            onTap: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: 20),
          _sectionTitle('EXPERIENCIA CON FUERZA'),
          _chipGroup<ExerciseExperienceLevel>(
            options: ExerciseExperienceLevel.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _experience == v,
            onTap: (v) => setState(() => _experience = v),
          ),
          const SizedBox(height: 20),
          _sectionTitle('EQUIPO DISPONIBLE'),
          _chipGroup<ExerciseEquipment>(
            options: ExerciseEquipment.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _equipment == v,
            onTap: (v) => setState(() => _equipment = v),
          ),
          const SizedBox(height: 20),
          _sectionTitle('QUÉ TE GUSTA (opcional)'),
          _chipGroup<ExercisePreferenceTag>(
            options: ExercisePreferenceTag.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _liked.contains(v),
            onTap: (v) => setState(() {
              if (v == ExercisePreferenceTag.ninguna) {
                _liked
                  ..clear()
                  ..add(v);
              } else {
                _liked.remove(ExercisePreferenceTag.ninguna);
                if (!_liked.remove(v)) _liked.add(v);
              }
            }),
          ),
          const SizedBox(height: 20),
          _sectionTitle('OBJETIVO DE COMPOSICIÓN CORPORAL'),
          _chipGroup<BodyCompositionGoal>(
            options: BodyCompositionGoal.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _goal == v,
            onTap: (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 20),
          _sectionTitle('LESIONES O LIMITACIONES (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Nunca te vamos a prescribir carga sobre una lesión activa.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          _chipGroup<InjuryTag>(
            options: InjuryTag.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _injuries.contains(v),
            onTap: (v) => setState(() {
              if (!_injuries.remove(v)) _injuries.add(v);
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _injuryNotesController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Detalle opcional (ej: "hernia L4-L5 diagnosticada")',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
              ),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pillarEjercicio,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'GUARDAR',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _chipGroup<T>({
    required List<T> options,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => _chip(
                label: labelOf(o),
                selected: isSelected(o),
                onTap: () => onTap(o),
              ))
          .toList(),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const accent = AppColors.pillarEjercicio;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : Colors.white10,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? accent : Colors.white70,
          ),
        ),
      ),
    );
  }
}
