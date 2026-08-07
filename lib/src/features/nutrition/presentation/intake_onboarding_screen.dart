// SPEC-270 (fase 2) — Onboarding del Pilar de Alimentación: la evaluación
// dietética en 6 bloques. Arma un `IntakeDraft` y, al terminar, lo guarda
// vía `NutritionIntakeNotifier.saveIntake` (que deriva proteína/ventana
// desde el UserModel — no pide biometría nueva).
//
// Consigna de UX: "cuéntanos cómo comes, sea lo que sea". Captura
// descriptiva, sin juzgar, sin gramos ni calorías (NUTRITION_BIBLIOGRAPHY
// §1.2). El armado draft → dominio vive en intake_draft.dart (testeado);
// este widget solo pinta y maneja gestos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/intake_draft.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const Color _amber = AppColors.pillarNutricion;

class IntakeOnboardingScreen extends ConsumerStatefulWidget {
  const IntakeOnboardingScreen({super.key});

  @override
  ConsumerState<IntakeOnboardingScreen> createState() =>
      _IntakeOnboardingScreenState();
}

class _IntakeOnboardingScreenState
    extends ConsumerState<IntakeOnboardingScreen> {
  static const int _stepCount = 6;
  final PageController _pageController = PageController();
  int _step = 0;
  bool _saving = false;
  late IntakeDraft _draft;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(nutritionIntakeNotifierProvider).intake;
    if (existing != null) {
      _draft = IntakeDraft.fromIntake(existing);
    } else {
      final user = ref.read(currentUserStreamProvider).valueOrNull;
      _draft = IntakeDraft.initial(
        breakfastTime: _fmt(user?.profile.firstMealGoal),
        dinnerTime: _fmt(user?.profile.lastMealGoal),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
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
                  _StepStructure(draft: _draft, onChanged: _refresh),
                  _StepMeals(draft: _draft, onChanged: _refresh),
                  _StepSnacks(draft: _draft, onChanged: _refresh),
                  _StepDrinks(draft: _draft, onChanged: _refresh),
                  _StepRestrictions(draft: _draft, onChanged: _refresh),
                  _StepContext(draft: _draft, onChanged: _refresh),
                ],
              ),
            ),
            _BottomBar(
              step: _step,
              total: _stepCount,
              isLast: isLast,
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

  void _refresh() => setState(() {});
}

// ─── Progreso ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: List.generate(total, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: active ? _amber : AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Barra inferior ───────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int step;
  final int total;
  final bool isLast;
  final bool saving;
  final bool canFinish;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomBar({
    required this.step,
    required this.total,
    required this.isLast,
    required this.saving,
    required this.canFinish,
    required this.onBack,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          if (step > 0)
            TextButton(
              onPressed: saving ? null : onBack,
              child: const Text('Atrás',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: saving
                ? null
                : (isLast ? (canFinish ? onFinish : null) : onNext),
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.bgElevated,
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
                : Text(
                    isLast ? 'Guardar' : 'Siguiente',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Andamiaje de paso ────────────────────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ─── Bloque 1: estructura ─────────────────────────────────────────────────

class _StepStructure extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepStructure({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cuántas comidas haces al día?',
      subtitle: 'Cuéntanos tu rutina real. No hay respuesta correcta.',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(6, (i) {
            final value = i + 1;
            return _ChoicePill(
              label: '$value',
              selected: draft.mealsPerDay == value,
              onTap: () {
                draft.mealsPerDay = value;
                onChanged();
              },
            );
          }),
        ),
        const SizedBox(height: 12),
        const Text(
          'En el siguiente paso armas cada comida con lo que sueles comer.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

// ─── Bloque 2: qué comes (con cantidades) ─────────────────────────────────

class _StepMeals extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepMeals({required this.draft, required this.onChanged});

  static String _slotLabel(MealSlot s) => switch (s) {
        MealSlot.breakfast => 'Desayuno',
        MealSlot.lunch => 'Almuerzo',
        MealSlot.dinner => 'Cena',
        MealSlot.other => 'Otra comida',
      };

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Qué comes en cada comida',
      subtitle: 'Agrega lo que sueles comer y ajusta la cantidad al ojo '
          '(poco / normal / bastante). Sin pesar nada.',
      children: [
        for (final meal in draft.meals)
          _MealCard(
            title: _slotLabel(meal.slot),
            meal: meal,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final DraftMeal meal;
  final VoidCallback onChanged;
  const _MealCard({
    required this.title,
    required this.meal,
    required this.onChanged,
  });

  Future<void> _addFood(BuildContext context) async {
    final item = await showModalBottomSheet<IntakeItem>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _FoodPickerSheet(),
    );
    if (item != null) {
      meal.items.add(item);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < meal.items.length; i++)
            _ItemRow(
              item: meal.items[i],
              onQty: (q) {
                meal.items[i] = IntakeItem(
                  foodId: meal.items[i].foodId,
                  freeText: meal.items[i].freeText,
                  qty: q,
                );
                onChanged();
              },
              onDelete: () {
                meal.items.removeAt(i);
                onChanged();
              },
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _addFood(context),
            icon: const Icon(Icons.add, size: 18, color: _amber),
            label: const Text('Agregar alimento',
                style: TextStyle(color: _amber, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final IntakeItem item;
  final ValueChanged<PortionQty> onQty;
  final VoidCallback onDelete;
  const _ItemRow({
    required this.item,
    required this.onQty,
    required this.onDelete,
  });

  String get _name {
    if (item.foodId != null && item.foodId!.isNotEmpty) {
      final match = FoodCatalog.all.where((f) => f.id == item.foodId);
      if (match.isNotEmpty) return match.first.name;
      return item.foodId!;
    }
    return item.freeText ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 6),
                _QtyToggle(qty: item.qty, onQty: onQty),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _QtyToggle extends StatelessWidget {
  final PortionQty qty;
  final ValueChanged<PortionQty> onQty;
  const _QtyToggle({required this.qty, required this.onQty});

  static String _label(PortionQty q) => switch (q) {
        PortionQty.little => 'Poco',
        PortionQty.normal => 'Normal',
        PortionQty.plenty => 'Bastante',
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: PortionQty.values.map((q) {
        return _ChoicePill(
          label: _label(q),
          selected: qty == q,
          dense: true,
          onTap: () => onQty(q),
        );
      }).toList(),
    );
  }
}

// ─── Bloque 3: snacks ─────────────────────────────────────────────────────

class _StepSnacks extends StatefulWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepSnacks({required this.draft, required this.onChanged});

  @override
  State<_StepSnacks> createState() => _StepSnacksState();
}

class _StepSnacksState extends State<_StepSnacks> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.draft.snacks.add(
      IntakeSnack(freeText: text, frequency: ConsumptionFrequency.sometimes),
    );
    _controller.clear();
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Snacks y "galguerías"',
      subtitle: 'Lo que picas entre comidas: dulces, paquetes, fruta, '
          'frutos secos… lo que sea.',
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Ej. galletas, papas fritas…'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: _amber, size: 30),
              onPressed: _add,
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < widget.draft.snacks.length; i++)
          _SnackRow(
            snack: widget.draft.snacks[i],
            onFreq: (f) {
              final s = widget.draft.snacks[i];
              widget.draft.snacks[i] = IntakeSnack(
                  foodId: s.foodId, freeText: s.freeText, frequency: f);
              widget.onChanged();
              setState(() {});
            },
            onDelete: () {
              widget.draft.snacks.removeAt(i);
              widget.onChanged();
              setState(() {});
            },
          ),
        if (widget.draft.snacks.isEmpty)
          const Text('Si no picas nada entre comidas, sigue de largo.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );
  }
}

class _SnackRow extends StatelessWidget {
  final IntakeSnack snack;
  final ValueChanged<ConsumptionFrequency> onFreq;
  final VoidCallback onDelete;
  const _SnackRow({
    required this.snack,
    required this.onFreq,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snack.freeText ?? snack.foodId ?? '—',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                const SizedBox(height: 6),
                _FreqToggle(freq: snack.frequency, onFreq: onFreq),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Bloque 4: bebidas ────────────────────────────────────────────────────

class _StepDrinks extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepDrinks({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Bebidas',
      subtitle: 'Gaseosas, jugos, café y alcohol cuentan mucho en el '
          'metabolismo.',
      children: [
        const _FieldLabel('Bebidas azucaradas (gaseosa, jugo, energizante)'),
        _FreqToggle(
          freq: draft.sugary,
          onFreq: (f) {
            draft.sugary = f;
            onChanged();
          },
        ),
        const SizedBox(height: 18),
        _SwitchRow(
          label: '¿Endulzas el café o el té?',
          value: draft.coffeeSweetened,
          onChanged: (v) {
            draft.coffeeSweetened = v;
            onChanged();
          },
        ),
        _SwitchRow(
          label: '¿Tomas alcohol?',
          helper: 'Lo llevamos con el Protocolo de Consumo Consciente.',
          value: draft.drinksAlcohol,
          onChanged: (v) {
            draft.drinksAlcohol = v;
            onChanged();
          },
        ),
      ],
    );
  }
}

// ─── Bloque 5: restricciones ──────────────────────────────────────────────

class _StepRestrictions extends StatefulWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepRestrictions({required this.draft, required this.onChanged});

  @override
  State<_StepRestrictions> createState() => _StepRestrictionsState();
}

class _StepRestrictionsState extends State<_StepRestrictions> {
  final TextEditingController _excludeCtrl = TextEditingController();
  final TextEditingController _allergyCtrl = TextEditingController();

  @override
  void dispose() {
    _excludeCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  static String _dietLabel(DietType d) => switch (d) {
        DietType.omnivore => 'Como de todo',
        DietType.pescatarian => 'Pescetariano',
        DietType.vegetarian => 'Vegetariano',
        DietType.vegan => 'Vegano',
        DietType.other => 'Otro',
      };

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return _StepScaffold(
      title: 'Preferencias y lo que no comes',
      subtitle: 'Para que la minuta nunca te proponga algo que no comes.',
      children: [
        const _FieldLabel('Tu régimen'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DietType.values.map((d) {
            return _ChoicePill(
              label: _dietLabel(d),
              selected: draft.diet == d,
              onTap: () {
                draft.diet = d;
                widget.onChanged();
                setState(() {});
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Alimentos que NO comes'),
        _ChipInput(
          controller: _excludeCtrl,
          hint: 'Ej. cerdo, hígado…',
          values: draft.excludes,
          onChanged: () {
            widget.onChanged();
            setState(() {});
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Alergias o intolerancias'),
        _ChipInput(
          controller: _allergyCtrl,
          hint: 'Ej. maní, lactosa, gluten…',
          values: draft.allergies,
          onChanged: () {
            widget.onChanged();
            setState(() {});
          },
        ),
      ],
    );
  }
}

// ─── Bloque 6: contexto ───────────────────────────────────────────────────

class _StepContext extends StatelessWidget {
  final IntakeDraft draft;
  final VoidCallback onChanged;
  const _StepContext({required this.draft, required this.onChanged});

  static String _levelLabel(LevelLowMidHigh l) => switch (l) {
        LevelLowMidHigh.low => 'Poco',
        LevelLowMidHigh.mid => 'Medio',
        LevelLowMidHigh.high => 'Bastante',
      };

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Tu día a día',
      subtitle: 'Esto define qué tan ambiciosa puede ser tu minuta.',
      children: [
        const _FieldLabel('Tiempo para cocinar'),
        _LevelToggle(
          value: draft.cookTime,
          label: _levelLabel,
          onChanged: (v) {
            draft.cookTime = v;
            onChanged();
          },
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Presupuesto para mercado'),
        _LevelToggle(
          value: draft.budget,
          label: _levelLabel,
          onChanged: (v) {
            draft.budget = v;
            onChanged();
          },
        ),
        const SizedBox(height: 10),
        _SwitchRow(
          label: '¿Cocinas en casa?',
          value: draft.cooksAtHome,
          onChanged: (v) {
            draft.cooksAtHome = v;
            onChanged();
          },
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _amber.withValues(alpha: 0.30)),
          ),
          child: const Text(
            'Con esto armamos tu minuta diaria: cambiaremos lo que menos te '
            'ayuda, poco a poco, respetando lo que ya te gusta.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 12 : 16, vertical: dense ? 6 : 10),
        decoration: BoxDecoration(
          color:
              selected ? _amber.withValues(alpha: 0.18) : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _amber : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _amber : AppColors.textSecondary,
            fontSize: dense ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FreqToggle extends StatelessWidget {
  final ConsumptionFrequency freq;
  final ValueChanged<ConsumptionFrequency> onFreq;
  const _FreqToggle({required this.freq, required this.onFreq});

  static String _label(ConsumptionFrequency f) => switch (f) {
        ConsumptionFrequency.never => 'Nunca',
        ConsumptionFrequency.sometimes => 'A veces',
        ConsumptionFrequency.daily => 'A diario',
        ConsumptionFrequency.multipleDaily => 'Varias/día',
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ConsumptionFrequency.values.map((f) {
        return _ChoicePill(
          label: _label(f),
          selected: freq == f,
          dense: true,
          onTap: () => onFreq(f),
        );
      }).toList(),
    );
  }
}

class _LevelToggle extends StatelessWidget {
  final LevelLowMidHigh value;
  final String Function(LevelLowMidHigh) label;
  final ValueChanged<LevelLowMidHigh> onChanged;
  const _LevelToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: LevelLowMidHigh.values.map((l) {
        return _ChoicePill(
          label: label(l),
          selected: value == l,
          dense: true,
          onTap: () => onChanged(l),
        );
      }).toList(),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(helper!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _amber,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ChipInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> values;
  final VoidCallback onChanged;
  const _ChipInput({
    required this.controller,
    required this.hint,
    required this.values,
    required this.onChanged,
  });

  void _add() {
    final t = controller.text.trim();
    if (t.isEmpty || values.contains(t)) {
      controller.clear();
      return;
    }
    values.add(t);
    controller.clear();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(hint),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: _amber, size: 30),
              onPressed: _add,
            ),
          ],
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((v) {
              return Chip(
                label: Text(v,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                backgroundColor: AppColors.bgElevated,
                deleteIconColor: AppColors.textMuted,
                onDeleted: () {
                  values.remove(v);
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bgSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _amber),
      ),
    );

// ─── Selector de alimentos (bottom sheet) ─────────────────────────────────

class _FoodPickerSheet extends StatefulWidget {
  const _FoodPickerSheet();

  @override
  State<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends State<_FoodPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.trim().isEmpty
        ? const <Food>[]
        : FoodCatalog.search(_query, limit: 12);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Busca un alimento…'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      for (final food in results)
                        _FoodTile(
                          title: food.name,
                          subtitle: food.portionLabel,
                          onTap: () => Navigator.of(context)
                              .pop(IntakeItem(foodId: food.id)),
                        ),
                      if (_query.trim().isNotEmpty)
                        _FoodTile(
                          title: 'Usar "${_query.trim()}"',
                          subtitle: 'No está en la lista — lo agregamos igual',
                          onTap: () => Navigator.of(context).pop(
                            IntakeItem(freeText: _query.trim()),
                          ),
                        ),
                      if (_query.trim().isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Text(
                            'Escribe para buscar. Si no aparece, igual puedes '
                            'agregarlo como texto.',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _FoodTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.add, color: _amber, size: 20),
      onTap: onTap,
    );
  }
}
