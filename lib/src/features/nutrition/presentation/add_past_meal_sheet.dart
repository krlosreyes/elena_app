// SPEC-71.3: AddPastMealSheet con macros (SPEC-64) + catálogo
// (NutritionFactsLookup).
//
// Antes: solo capturaba label + mealTime. NutritionLog soporta desde
// SPEC-64 macros opcionales (calories, protein, carbs, fat, fiber,
// glycemicIndex) y NutritionFactsLookup ofrece 25 alimentos comunes
// con datos USDA. Nada de eso era alcanzable desde UI.
//
// Ahora: el bloque básico (label + time + ventana circadiana) sigue
// arriba, idéntico de rápido para registros sin desglose. Debajo, un
// toggle "Más detalle" expone:
//   - Picker de catálogo: search bar → lista filtrada → autofill macros.
//   - 6 inputs editables después del autofill (el usuario puede ajustar).
//   - X clear-all que vuelve a "no medido".
//
// Si el usuario deja todo vacío, el log se persiste con macros=null —
// igual que antes. El IMR no se afecta (peso 0.12 deliberadamente bajo
// hasta que macros entren al cómputo en SPEC futura).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_facts_lookup.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/meal_time_picker.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class AddPastMealSheet extends ConsumerStatefulWidget {
  const AddPastMealSheet({super.key});

  @override
  ConsumerState<AddPastMealSheet> createState() => _AddPastMealSheetState();
}

class _AddPastMealSheetState extends ConsumerState<AddPastMealSheet> {
  static const _accentColor = Color(0xFF2D9B60);

  late TimeOfDay _selectedTime;
  String _selectedMeal = 'Desayuno';
  bool _isSaving = false;
  bool _isOutsideWindow = false;

  final List<String> _mealOptions = ['Desayuno', 'Almuerzo', 'Cena', 'Snack'];

  // SPEC-71.3: detalle SPEC-64.
  bool _showDetail = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // Cuando es null, los inputs muestran "—". Cuando autofill desde
  // catálogo, todos se llenan; el usuario puede editar después.
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _glycemicIndexController = TextEditingController();
  // Source tracking: si autofill vino del catálogo, lo marcamos como
  // tal en el log persistido. Si el usuario edita después, se queda
  // como `userInput` (decisión: la edición prevalece sobre el origen).
  NutritionLogSource _source = NutritionLogSource.userInput;
  bool _hasAnyMacroInput = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _checkIfOutsideWindow();

    // Listeners para detectar cualquier input manual.
    for (final c in [
      _caloriesController,
      _proteinController,
      _carbsController,
      _fatController,
      _fiberController,
      _glycemicIndexController,
    ]) {
      c.addListener(_recomputeMacroState);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _glycemicIndexController.dispose();
    super.dispose();
  }

  void _recomputeMacroState() {
    final has = _caloriesController.text.isNotEmpty ||
        _proteinController.text.isNotEmpty ||
        _carbsController.text.isNotEmpty ||
        _fatController.text.isNotEmpty ||
        _fiberController.text.isNotEmpty ||
        _glycemicIndexController.text.isNotEmpty;
    if (has != _hasAnyMacroInput) {
      setState(() => _hasAnyMacroInput = has);
    }
  }

  void _checkIfOutsideWindow() {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final first = user.profile.firstMealGoal;
    final last = user.profile.lastMealGoal;
    if (first == null || last == null) return;

    final timeMinutes = _selectedTime.hour * 60 + _selectedTime.minute;
    final firstMinutes = first.hour * 60 + first.minute;
    final lastMinutes = last.hour * 60 + last.minute;

    setState(() {
      _isOutsideWindow =
          !(timeMinutes >= firstMinutes && timeMinutes <= lastMinutes);
    });
  }

  void _applyEntry(NutritionFactsEntry entry) {
    setState(() {
      _caloriesController.text = entry.calories.toStringAsFixed(0);
      _proteinController.text = entry.protein.toStringAsFixed(1);
      _carbsController.text = entry.carbs.toStringAsFixed(1);
      _fatController.text = entry.fat.toStringAsFixed(1);
      _fiberController.text = entry.fiber?.toStringAsFixed(1) ?? '';
      _glycemicIndexController.text =
          entry.glycemicIndex?.toString() ?? '';
      _source = NutritionLogSource.catalog;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _clearAllMacros() {
    setState(() {
      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      _fiberController.clear();
      _glycemicIndexController.clear();
      _source = NutritionLogSource.userInput;
    });
  }

  double? _parseDouble(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  int? _parseInt(TextEditingController c) {
    final s = c.text.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  Future<void> _saveMeal() async {
    if (_isSaving) return;

    final now = DateTime.now();
    final mealDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() => _isSaving = true);

    try {
      // Si el usuario edito macros después del autofill desde catálogo,
      // mantenemos la marca catalog (los datos siguen viniendo de ese
      // origen aunque haya ajustes). Solo si nunca tocó el catálogo,
      // queda como userInput.
      final source = _source;

      await ref.read(nutritionProvider.notifier).logMeal(
            label: _selectedMeal,
            mealTime: mealDateTime,
            calories: _parseDouble(_caloriesController),
            protein: _parseDouble(_proteinController),
            carbs: _parseDouble(_carbsController),
            fat: _parseDouble(_fatController),
            fiber: _parseDouble(_fiberController),
            glycemicIndex: _parseInt(_glycemicIndexController),
            source: source,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ $_selectedMeal registrado a las ${_selectedTime.format(context)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _accentColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red.withValues(alpha: 0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserStreamProvider).value;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ─────────────────────────────────────────────
              const Text(
                'REGISTRAR COMIDA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registra qué comiste hoy. Los macros son opcionales.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),

              // ── Selector de tipo de comida ────────────────────────
              Text(
                'TIPO DE COMIDA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _mealOptions.map((meal) {
                  final isSelected = _selectedMeal == meal;
                  return FilterChip(
                    label: Text(
                      meal,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedMeal = meal);
                    },
                    backgroundColor: Colors.transparent,
                    selectedColor: _accentColor.withValues(alpha: 0.3),
                    side: BorderSide(
                      color: isSelected
                          ? _accentColor
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Time Picker ────────────────────────────────────────
              MealTimePicker(
                initialTime: _selectedTime,
                label: 'HORA DE LA COMIDA',
                onTimeSelected: (dateTime) {
                  setState(() {
                    _selectedTime = TimeOfDay.fromDateTime(dateTime);
                    _checkIfOutsideWindow();
                  });
                },
              ),
              const SizedBox(height: 16),

              // ── Advertencia ventana circadiana ────────────────────
              if (_isOutsideWindow) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fuera de ventana circadiana',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Esta comida está fuera de tu ventana configurada (${user?.profile.firstMealGoal?.hour}:${user?.profile.firstMealGoal?.minute.toString().padLeft(2, '0')} - ${user?.profile.lastMealGoal?.hour}:${user?.profile.lastMealGoal?.minute.toString().padLeft(2, '0')})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Toggle detalle (SPEC-64 macros) ───────────────────
              _DetailToggle(
                isExpanded: _showDetail,
                onToggle: () => setState(() => _showDetail = !_showDetail),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                child: _showDetail
                    ? _buildDetailSection()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 20),

              // ── CTA primario ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMeal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar comida',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar del catálogo ──────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar alimento (huevo, pollo, arroz...)',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.40),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withValues(alpha: 0.45),
                          size: 18,
                        ),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) _buildSearchResults(),
          const SizedBox(height: 16),

          // Header macros ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  _hasAnyMacroInput ? 'MACRONUTRIENTES' : 'MACROS (NO MEDIDOS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_hasAnyMacroInput)
                GestureDetector(
                  onTap: _clearAllMacros,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_source == NutritionLogSource.catalog) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 11, color: _accentColor.withValues(alpha: 0.9)),
                  const SizedBox(width: 4),
                  Text(
                    'Auto-rellenado desde catálogo (puedes ajustar)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _accentColor.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Inputs de macros ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MacroInput(
                  label: 'Calorías',
                  suffix: 'kcal',
                  controller: _caloriesController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroInput(
                  label: 'Proteína',
                  suffix: 'g',
                  controller: _proteinController,
                  allowDecimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MacroInput(
                  label: 'Carbohidratos',
                  suffix: 'g',
                  controller: _carbsController,
                  allowDecimal: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroInput(
                  label: 'Grasa',
                  suffix: 'g',
                  controller: _fatController,
                  allowDecimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MacroInput(
                  label: 'Fibra',
                  suffix: 'g',
                  controller: _fiberController,
                  allowDecimal: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroInput(
                  label: 'IG',
                  suffix: '0–100',
                  controller: _glycemicIndexController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = NutritionFactsLookup.search(_searchQuery);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sin resultados en el catálogo. Puedes ingresar los macros manualmente abajo.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: results.take(6).map((entry) {
          return InkWell(
            onTap: () => _applyEntry(entry),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.servingDescription} · ${entry.calories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: _accentColor,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DetailToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DetailToggle({required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              isExpanded ? 'Ocultar detalle' : 'Más detalle (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              'Catálogo + macros',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroInput extends StatelessWidget {
  final String label;
  final String suffix;
  final TextEditingController controller;
  final bool allowDecimal;

  const _MacroInput({
    required this.label,
    required this.suffix,
    required this.controller,
    this.allowDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: allowDecimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: allowDecimal
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  LengthLimitingTextInputFormatter(6),
                ]
              : [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '—',
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.30)),
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF2D9B60), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }
}
