// SPEC-289 (fase 3) — Onboarding de alimentación por CHECKLISTS.
//
// Reemplaza la captura por comida (buscar alimento por comida + poco/normal/
// bastante), que era tediosa y fea. Ahora el usuario:
//   1) elige su régimen,
//   2) marca lo que come (por macro: Proteínas / Carbohidratos / Grasas /
//      Comidas y antojos) — no importa en qué comida, el motor decide,
//   3) marca lo que pica (snacks),
//   4) declara alergias.
// Lo que NO marca = no lo come. Arma un `IntakeDraft` (repertorio) y lo guarda
// vía `NutritionIntakeNotifier.saveIntake`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/intake_draft.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/food_emoji.dart';
import 'package:elena_app/src/features/nutrition/domain/food_quality.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

const Color _amber = AppColors.pillarNutricion;

/// Snacks curados (ids reales del catálogo) para el paso de "lo que picas".
const List<String> _snackIds = [
  'almendras',
  'nueces',
  'mani',
  'yogur_griego',
  'manzana',
  'banano',
  'platano',
  'galletas',
  'chocolatina',
  'helado',
  'papas_fritas',
  'chips',
];

/// Alérgenos frecuentes para marcar rápido.
const List<String> _commonAllergens = [
  'Gluten',
  'Lactosa',
  'Maní',
  'Frutos secos',
  'Mariscos',
  'Huevo',
  'Soya',
];

class IntakeOnboardingScreen extends ConsumerStatefulWidget {
  const IntakeOnboardingScreen({super.key});

  @override
  ConsumerState<IntakeOnboardingScreen> createState() =>
      _IntakeOnboardingScreenState();
}

class _IntakeOnboardingScreenState
    extends ConsumerState<IntakeOnboardingScreen> {
  // Régimen + 4 grupos de alimentos + snacks + alergias.
  static const int _stepCount = 7;
  final PageController _pageController = PageController();
  int _step = 0;
  bool _saving = false;
  late IntakeDraft _draft;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(nutritionIntakeNotifierProvider).intake;
    _draft = existing != null
        ? IntakeDraft.fromIntake(existing)
        : IntakeDraft.initial();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_step < _stepCount - 1) _goTo(_step + 1);
  }

  void _back() {
    if (_step > 0) _goTo(_step - 1);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await ref
        .read(nutritionIntakeNotifierProvider.notifier)
        .saveIntake(_draft.build());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listo. Con esto armaremos tu minuta diaria.'),
        backgroundColor: _amber,
      ),
    );
    Navigator.of(context).pop();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isLast = _step == _stepCount - 1;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cómo comes hoy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ProgressBar(step: _step, total: _stepCount),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepDiet(draft: _draft, onChanged: _refresh),
                  for (final group in UserFoodGroup.values)
                    _StepFoodGroup(
                        group: group, draft: _draft, onChanged: _refresh),
                  _StepSnacks(draft: _draft, onChanged: _refresh),
                  _StepAllergies(draft: _draft, onChanged: _refresh),
                ],
              ),
            ),
            _BottomBar(
              isLast: isLast,
              showBack: _step > 0,
              saving: _saving,
              canFinish: _draft.isComplete,
              onBack: _back,
              onNext: _next,
              onFinish: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progreso ────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? _amber : AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Barra inferior ──────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isLast;
  final bool showBack;
  final bool saving;
  final bool canFinish;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  const _BottomBar({
    required this.isLast,
    required this.showBack,
    required this.saving,
    required this.canFinish,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = isLast ? (canFinish && !saving) : true;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (showBack)
            TextButton(
              onPressed: onBack,
              child: const Text('Atrás',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: enabled ? (isLast ? onFinish : onNext) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: Colors.black,
              disabledBackgroundColor: _amber.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : Text(isLast ? 'Guardar' : 'Siguiente',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Andamio de paso ─────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ─── Paso 1: régimen ─────────────────────────────────────────────────────────

class _StepDiet extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepDiet({required this.draft, required this.onChanged});

  static const _options = <(DietType, String)>[
    (DietType.omnivore, 'Como de todo'),
    (DietType.pescatarian, 'Pescetariano'),
    (DietType.vegetarian, 'Vegetariano'),
    (DietType.vegan, 'Vegano'),
    (DietType.other, 'Otro'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Tu régimen',
      subtitle: 'Así la minuta nunca te propone algo fuera de lo tuyo.',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (diet, label) in _options)
              _SelectChip(
                label: label,
                selected: draft.diet == diet,
                onTap: () {
                  draft.diet = diet;
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Pasos 2-5: marca lo que comes (una pantalla por macro) ──────────────────

class _StepFoodGroup extends StatefulWidget {
  final UserFoodGroup group;
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepFoodGroup({
    required this.group,
    required this.draft,
    required this.onChanged,
  });

  static String subtitleFor(UserFoodGroup g) => switch (g) {
        UserFoodGroup.protein =>
          'Carnes, huevo, pescado, lácteos, legumbres. Marca lo tuyo.',
        UserFoodGroup.carb =>
          'Verduras, frutas, granos y harinas. Marca lo que sueles comer.',
        UserFoodGroup.fat =>
          'Aceites, aguacate, frutos secos, quesos. Marca lo tuyo.',
        UserFoodGroup.combo =>
          'Platos y comida rápida del día a día. Marca lo que comes.',
      };

  @override
  State<_StepFoodGroup> createState() => _StepFoodGroupState();
}

class _StepFoodGroupState extends State<_StepFoodGroup> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = FoodCatalog.byUserGroup(widget.group);
    final foods = _query.isEmpty
        ? all
        : all.where((f) => f.matchesQuery(_query)).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.group.label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(_StepFoodGroup.subtitleFor(widget.group),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Busca en ${widget.group.label.toLowerCase()}…',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: AppColors.bgSurface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _amber),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: foods.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'Sin resultados. Prueba otra palabra.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final f in foods)
                          _SelectChip(
                            label: f.name,
                            emoji: foodEmoji(f),
                            warn: FoodQuality.isPoor(f),
                            selected: widget.draft.has(f.id),
                            onTap: () {
                              widget.draft.toggle(f.id);
                              widget.onChanged();
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Paso 3: snacks ──────────────────────────────────────────────────────────

class _StepSnacks extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepSnacks({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final snacks = _snackIds
        .map(FoodCatalog.byId)
        .whereType<Food>()
        .toList(growable: false);
    return _StepScaffold(
      title: 'Lo que picas entre comidas',
      subtitle: 'Snacks, dulces, fruta, frutos secos. Marca lo tuyo; si no '
          'picas nada, sigue de largo.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in snacks)
              _SelectChip(
                label: f.name,
                emoji: foodEmoji(f),
                warn: FoodQuality.isPoor(f),
                selected: draft.hasSnack(f.id),
                onTap: () {
                  draft.toggleSnack(f.id);
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Paso 4: alergias ────────────────────────────────────────────────────────

class _StepAllergies extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepAllergies({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Alergias o intolerancias',
      subtitle: 'Marca lo que debes evitar. Nunca te lo propondremos.',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final a in _commonAllergens)
              _SelectChip(
                label: a,
                selected: draft.allergies.contains(a),
                onTap: () {
                  if (!draft.allergies.remove(a)) draft.allergies.add(a);
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Si tienes otra que no está aquí, podrás agregarla luego desde tu '
          'perfil.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
      ],
    );
  }
}

// ─── Piezas compartidas ──────────────────────────────────────────────────────

class _SelectChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;

  /// SPEC-292: marca visual de "alimento poco ideal" (ultraprocesado / alto
  /// impacto). No bloquea — el usuario decide; en la minuta le damos opciones.
  final bool warn;
  final VoidCallback onTap;
  const _SelectChip({
    required this.label,
    this.emoji = '',
    this.warn = false,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? _amber.withValues(alpha: 0.16) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _amber : AppColors.borderDefault,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 7),
            ] else if (selected) ...[
              const Icon(Icons.check, size: 16, color: _amber),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _amber : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (warn) ...[
              const SizedBox(width: 5),
              const Icon(Icons.warning_amber_rounded,
                  size: 13, color: AppColors.statusWarn),
            ],
          ],
        ),
      ),
    );
  }
}
