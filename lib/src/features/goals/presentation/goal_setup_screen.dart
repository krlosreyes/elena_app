// SPEC-14 (revisión): Objetivos del Usuario — Pantalla de confirmación de metas
//
// Elena analiza el perfil biométrico del usuario y propone objetivos
// científicamente fundamentados. El usuario no configura desde cero:
// confirma, ajusta ligeramente o desactiva cada sugerencia.
//
// Flujo:
//   1. GoalSuggestionEngine genera sugerencias desde UserModel
//   2. Las tarjetas muestran "Elena sugiere: X" con la justificación
//   3. El usuario afina con un slider de rango reducido (±20% del valor)
//   4. Guarda via GoalNotifier.saveAll()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_suggestion_engine.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  late Map<GoalType, _GoalDraft> _drafts;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _buildDrafts();
      _initialized = true;
    }
  }

  void _buildDrafts() {
    final userAsync     = ref.read(currentUserStreamProvider);
    final existingGoals = ref.read(goalsProvider);
    final user          = userAsync.valueOrNull;

    if (user == null) {
      // Fallback vacío — no debería ocurrir si la ruta está protegida
      _drafts = {
        for (final t in GoalType.values)
          t: _GoalDraft(type: t, target: 0, current: 0,
                        rationale: '', statusLabel: '', isActive: false),
      };
      return;
    }

    final suggestions = GoalSuggestionEngine.suggest(user);

    _drafts = {
      for (final type in GoalType.values)
        type: _GoalDraft(
          type:        type,
          target:      existingGoals[type]?.targetValue
                       ?? suggestions[type]!.suggestedTarget,
          current:     suggestions[type]!.currentValue,
          rationale:   suggestions[type]!.rationale,
          statusLabel: suggestions[type]!.currentStatusLabel,
          isActive:    existingGoals[type]?.isActive
                       ?? suggestions[type]!.shouldActivate,
          originalSuggestion: suggestions[type]!.suggestedTarget,
        ),
    };
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final Map<GoalType, UserGoal> goals = {};
    for (final draft in _drafts.values) {
      if (draft.isActive) {
        goals[draft.type] = UserGoal(
          type:        draft.type,
          targetValue: draft.target,
          startValue:  draft.current,
          isActive:    true,
          createdAt:   DateTime.now(),
        );
      }
    }
    await ref.read(goalsProvider.notifier).saveAll(goals);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Objetivos guardados ✓'),
          backgroundColor: Color(0xFF1ABC9C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _drafts.values.where((d) => d.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'OBJETIVOS DE ELENA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Encabezado: Elena habla ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1ABC9C).withOpacity(0.12),
                    const Color(0xFF1ABC9C).withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1ABC9C).withOpacity(0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧬', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Elena analizó tu perfil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculé estos objetivos con base en tu composición '
                          'corporal y hábitos actuales. Activa los que quieras '
                          'trabajar y ajusta si lo prefieres.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withOpacity(0.55),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de tarjetas ────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              children: [
                ...GoalType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SuggestionCard(
                    draft: _drafts[type]!,
                    onChanged: (updated) =>
                        setState(() => _drafts[type] = updated),
                  ),
                )),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── CTA ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: activeCount == 0 || _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1ABC9C),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        activeCount == 0
                            ? 'Activa al menos un objetivo'
                            : 'Confirmar $activeCount objetivo${activeCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Draft local de cada tarjeta ─────────────────────────────────────────────

class _GoalDraft {
  final GoalType type;
  final double   target;
  final double   current;
  final String   rationale;
  final String   statusLabel;
  final bool     isActive;
  final double?  originalSuggestion;

  const _GoalDraft({
    required this.type,
    required this.target,
    required this.current,
    required this.rationale,
    required this.statusLabel,
    required this.isActive,
    this.originalSuggestion,
  });

  _GoalDraft copyWith({double? target, bool? isActive}) => _GoalDraft(
        type:               type,
        target:             target ?? this.target,
        current:            current,
        rationale:          rationale,
        statusLabel:        statusLabel,
        isActive:           isActive ?? this.isActive,
        originalSuggestion: originalSuggestion,
      );
}

// ─── Tarjeta de sugerencia ────────────────────────────────────────────────────

class _SuggestionCard extends StatefulWidget {
  const _SuggestionCard({required this.draft, required this.onChanged});
  final _GoalDraft draft;
  final ValueChanged<_GoalDraft> onChanged;

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _showRationale = false;

  // ── Helpers de formato ──────────────────────────────────────────────────────

  String _fmt(GoalType type, double value) {
    switch (type) {
      case GoalType.weightTarget:          return '${value.toStringAsFixed(1)} kg';
      case GoalType.bodyFatTarget:         return '${value.toStringAsFixed(0)}%';
      case GoalType.fastingDaysPerWeek:    return '${value.toStringAsFixed(0)} días/sem';
      case GoalType.exerciseMinPerDay:     return '${value.toStringAsFixed(0)} min/día';
      case GoalType.sleepHoursPerNight:    return '${value.toStringAsFixed(1)} h/noche';
      case GoalType.hydrationLitersPerDay: return '${value.toStringAsFixed(2)} L/día';
    }
  }

  // Rango del slider: ±25% alrededor de la sugerencia, con mínimos de UserGoal
  double _sliderMin(UserGoal meta) {
    final s = widget.draft.originalSuggestion ?? widget.draft.target;
    return (s * 0.75).clamp(meta.sliderMin, meta.sliderMax);
  }

  double _sliderMax(UserGoal meta) {
    final s = widget.draft.originalSuggestion ?? widget.draft.target;
    return (s * 1.25).clamp(meta.sliderMin, meta.sliderMax);
  }

  double _snap(GoalType type, double raw) {
    switch (type) {
      case GoalType.weightTarget:          return (raw * 2).round() / 2;
      case GoalType.bodyFatTarget:         return raw.roundToDouble();
      case GoalType.fastingDaysPerWeek:    return raw.roundToDouble();
      case GoalType.exerciseMinPerDay:     return (raw / 5).round() * 5.0;
      case GoalType.sleepHoursPerNight:    return (raw * 2).round() / 2;
      case GoalType.hydrationLitersPerDay: return (raw * 4).round() / 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    // Meta vacía para acceder a propiedades estáticas (emoji, color, etc.)
    final meta = UserGoal(
      type:        draft.type,
      targetValue: draft.target,
      startValue:  draft.current,
      isActive:    draft.isActive,
      createdAt:   DateTime.now(),
    );

    final Color c = draft.isActive ? meta.pillarColor : Colors.white24;
    final bool  isSuggestionValue =
        widget.draft.originalSuggestion != null &&
        (draft.target - widget.draft.originalSuggestion!).abs() < 0.01;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: draft.isActive
            ? meta.pillarColor.withOpacity(0.07)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: draft.isActive
              ? meta.pillarColor.withOpacity(0.35)
              : Colors.white.withOpacity(0.06),
          width: draft.isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Fila principal ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji
                Text(meta.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),

                // Info central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + estado actual
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            meta.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: draft.isActive ? Colors.white : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge de estado actual
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              draft.statusLabel,
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: c,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Actual → Elena sugiere
                      Row(
                        children: [
                          Text(
                            'Actual: ${_fmt(draft.type, draft.current)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 10,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const Text(
                            'Elena: ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1ABC9C),
                            ),
                          ),
                          Text(
                            _fmt(draft.type, draft.target),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: draft.isActive ? c : Colors.white24,
                            ),
                          ),
                          if (isSuggestionValue) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF1ABC9C),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Toggle on/off
                GestureDetector(
                  onTap: () => widget.onChanged(
                    draft.copyWith(isActive: !draft.isActive),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    decoration: BoxDecoration(
                      color: draft.isActive ? c : Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: draft.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Sección expandida (rationale + slider) ───────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: draft.isActive
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Slider de ajuste fino
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor:   c,
                      inactiveTrackColor: Colors.white.withOpacity(0.08),
                      thumbColor:         c,
                      overlayColor:       c.withOpacity(0.12),
                      trackHeight:        4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                    ),
                    child: Slider(
                      value: draft.target.clamp(
                        _sliderMin(meta), _sliderMax(meta)),
                      min:       _sliderMin(meta),
                      max:       _sliderMax(meta),
                      onChanged: (val) => widget.onChanged(
                        draft.copyWith(target: _snap(draft.type, val)),
                      ),
                    ),
                  ),

                  // Etiquetas de rango del slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(draft.type, _sliderMin(meta)),
                          style: TextStyle(
                            fontSize: 8.5,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        // Botón de reset a sugerencia de Elena
                        if (!isSuggestionValue)
                          GestureDetector(
                            onTap: () => widget.onChanged(
                              draft.copyWith(
                                target: widget.draft.originalSuggestion
                                        ?? draft.target,
                              ),
                            ),
                            child: const Text(
                              '↺ Sugerencia de Elena',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF1ABC9C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          _fmt(draft.type, _sliderMax(meta)),
                          style: TextStyle(
                            fontSize: 8.5,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón "¿Por qué?" + rationale colapsable
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showRationale = !_showRationale),
                    child: Row(
                      children: [
                        Icon(
                          _showRationale
                              ? Icons.expand_less_rounded
                              : Icons.info_outline_rounded,
                          size: 13,
                          color: c.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showRationale
                              ? 'Ocultar explicación'
                              : '¿Por qué este objetivo?',
                          style: TextStyle(
                            fontSize: 10,
                            color: c.withOpacity(0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _showRationale
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                      child: Text(
                        draft.rationale,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withOpacity(0.6),
                          height: 1.6,
                        ),
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(height: 14),
          ),
        ],
      ),
    );
  }
}
