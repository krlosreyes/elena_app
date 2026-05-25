// SPEC-137 E.4: sheet de registro del pilar Nutrición — versión final.
//
// Cambios clave vs E.3:
// - Selector de alimentos por BUSCADOR (TextField con autocompletar)
//   inspirado en el patrón del AddPastMealSheet (que se elimina).
// - Score numérico continuo (0-100) por alimento. El círculo se colorea
//   por calidad promedio ponderada, no por categorías binarias A/E.
// - TimePicker para registrar comida pasada (unifica el flujo y permite
//   eliminar el AddPastMealSheet legacy).
// - Sin nomenclatura "Tipo A / Tipo E" en código ni UI (blindaje legal
//   respecto a marca registrada NaturalSlim®). Internamente usamos
//   `qualityScore`; al usuario solo le mostramos badge cualitativo.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/plate_builder.dart';

class PlateRatioSheet extends ConsumerStatefulWidget {
  /// Etiqueta semántica del plato. Si es null, el notifier usa el
  /// label sugerido según la hora del día.
  final String? label;

  /// Timestamp inicial del plato. Si es null, ahora. El usuario puede
  /// modificarlo via TimePicker (E.4 unifica el flujo "registrar comida
  /// pasada" que vivía en AddPastMealSheet).
  final DateTime? initialMealTime;

  const PlateRatioSheet({
    super.key,
    this.label,
    this.initialMealTime,
  });

  static Future<void> show(
    BuildContext context, {
    String? label,
    DateTime? initialMealTime,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlateRatioSheet(
        label: label,
        initialMealTime: initialMealTime,
      ),
    );
  }

  @override
  ConsumerState<PlateRatioSheet> createState() => _PlateRatioSheetState();
}

class _PlateRatioSheetState extends ConsumerState<PlateRatioSheet> {
  final PlateBuilder _builder = PlateBuilder();
  final TextEditingController _searchController = TextEditingController();
  late DateTime _mealTime;
  bool _submitting = false;
  bool _showTimePicker = false;
  // SPEC-137 E.5 fix: si el usuario NO tocó el TimePicker, el timestamp
  // del log debe ser el momento de CONFIRMAR (no el de abrir el sheet),
  // para que el countdown a la próxima comida arranque desde "ahora"
  // real y no desde "cuando se abrió el sheet hace 10 minutos".
  bool _userEditedTime = false;

  @override
  void initState() {
    super.initState();
    _mealTime = widget.initialMealTime ?? DateTime.now();
    // Si el caller pasó un timestamp explícito (caso "registrar comida
    // pasada"), respetarlo desde el inicio.
    _userEditedTime = widget.initialMealTime != null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cheatDay = ref.watch(cheatDayProvider);
    final cheatActive = cheatDay.isActiveToday;
    final quality = _builder.quality(cheatDayActive: cheatActive);
    final tip = _builder.tip(cheatDayActive: cheatActive);
    final searchResults = FoodCatalog.search(_searchController.text);
    // SPEC-137 E.5 fix: si el usuario NO tocó el TimePicker, la fila
    // de hora muestra "ahora" en vivo. Refresca cada 10s via el pulso.
    // Si tocó el picker (caso registrar comida pasada), respetamos
    // _mealTime ya editado.
    final pulse =
        ref.watch(metabolicPulseProvider).valueOrNull ?? DateTime.now();
    final displayedMealTime = _userEditedTime ? _mealTime : pulse;

    final mediaPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaPadding + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: 14),
              const Text(
                'Arma tu plato',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Buscá y agregá lo que comiste. El plato te dice qué tan sano fue.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(
                    painter: PlatePainter(
                      builder: _builder,
                      cheatDayActive: cheatActive,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _QualityBadge(quality: quality, tip: tip),
              const SizedBox(height: 14),
              if (_builder.isNotEmpty) ...[
                _SelectedChips(
                  builder: _builder,
                  onRemove: (food) =>
                      setState(() => _builder.remove(food)),
                ),
                const SizedBox(height: 14),
              ],
              _SearchField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              if (searchResults.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SearchResults(
                  results: searchResults,
                  onPick: (food) {
                    setState(() {
                      _builder.add(food);
                      _searchController.clear();
                    });
                  },
                ),
              ],
              const SizedBox(height: 14),
              _MealTimeRow(
                mealTime: displayedMealTime,
                expanded: _showTimePicker,
                onToggle: () =>
                    setState(() => _showTimePicker = !_showTimePicker),
                onTimePicked: (t) {
                  setState(() {
                    // Anclamos el día al "ahora" en vivo (no al
                    // _mealTime stale del initState), luego el usuario
                    // ajusta hora/minuto.
                    final base = DateTime.now();
                    _mealTime = DateTime(
                      base.year,
                      base.month,
                      base.day,
                      t.hour,
                      t.minute,
                    );
                    // SPEC-137 E.5 fix: usuario tocó el TimePicker —
                    // respetar este timestamp en el submit (no
                    // sobrescribir con DateTime.now()).
                    _userEditedTime = true;
                  });
                },
              ),
              const SizedBox(height: 14),
              _CheatDayToggle(
                cheatDay: cheatDay,
                onActivate: _handleCheatDayActivate,
                onDeactivate: _handleCheatDayDeactivate,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _builder.isEmpty || _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.metabolicGreen,
                    foregroundColor: AppColors.bgBase,
                    disabledBackgroundColor:
                        AppColors.metabolicGreen.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        AppColors.bgBase.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bgBase,
                          ),
                        )
                      : const Text(
                          'Registrar plato',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.borderStrong,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Future<void> _submit({bool forceLog = false}) async {
    if (_builder.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final isCheatDay = ref.read(cheatDayProvider).isActiveToday;
      // SPEC-137 E.5 fix: si el usuario NO tocó el TimePicker, el
      // timestamp del log debe ser AHORA (no el momento en que abrió
      // el sheet). Esto evita que el countdown a la próxima comida
      // arranque 5-10 min "atrasado" por el tiempo que tardó en
      // armar el plato.
      final effectiveMealTime =
          _userEditedTime ? _mealTime : DateTime.now();
      await ref.read(nutritionProvider.notifier).logMeal(
            label: widget.label,
            mealTime: effectiveMealTime,
            ratio: _builder.derivedMealRatio,
            isCheatDay: isCheatDay,
            forceLog: forceLog,
          );
      if (mounted) Navigator.of(context).pop();
    } on MealTooSoonException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        await _showBlockedDialog(e);
      }
    } on MealIntervalWarning catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        await _showWarningDialog(e);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No pudimos guardar el plato. Reintenta. ($e)'),
            backgroundColor: AppColors.statusBad,
          ),
        );
      }
    }
  }

  /// Dialog para el caso `blocked` (< 2h desde última comida).
  /// Solo informa — sin opción de override.
  Future<void> _showBlockedDialog(MealTooSoonException e) async {
    final canRegisterTime = _formatTimeOfDay(e.canRegisterAt);
    final sinceMin = e.sinceLastMeal.inMinutes;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text(
          'Todavía es muy pronto',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tu última comida fue hace $sinceMin minutos. Tu cuerpo todavía '
          'tiene insulina alta. Esperá al menos hasta las '
          '$canRegisterTime para que la digestión se complete y mantengas '
          'tu metabolismo en flujo.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Dialog para el caso `warning` (2-3h). Permite registrar igual
  /// como decisión consciente del usuario.
  Future<void> _showWarningDialog(MealIntervalWarning e) async {
    final recommendedTime = _formatTimeOfDay(e.recommendedAt);
    final sinceMin = e.sinceLastMeal.inMinutes;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text(
          'Tu cuerpo necesita un poco más',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Tu última comida fue hace $sinceMin minutos. Lo ideal son 3 '
          'horas (a partir de las $recommendedTime) para que la insulina '
          'baje del todo. ¿Querés registrar igual?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Esperar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Registrar igual'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      await _submit(forceLog: true);
    }
  }

  static String _formatTimeOfDay(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _handleCheatDayActivate() async {
    final result = await ref.read(cheatDayProvider.notifier).activate();
    if (!mounted) return;
    switch (result) {
      case CheatDayActivationResult.activated:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Día de permitidos activo. Disfrutalo, sin culpa.'),
            backgroundColor: AppColors.accent,
          ),
        );
      case CheatDayActivationResult.alreadyActive:
        break;
      case CheatDayActivationResult.blockedByWeeklyLock:
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.bgElevated,
            title: const Text('Ya usaste tu día esta semana'),
            content: const Text(
              'Tu día de permitidos es uno por semana. Vuelve a activarlo '
              'el próximo lunes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _handleCheatDayDeactivate() async {
    await ref.read(cheatDayProvider.notifier).deactivateToday();
  }
}

// ── Painter del círculo ───────────────────────────────────────────────

/// Dibuja el plato sólido. Cada sector representa una categoría (proteína
/// / grasa / carbos) con tamaño proporcional a sus slots. El COLOR de
/// cada sector refleja la calidad promedio de los alimentos de esa
/// categoría (verde si score alto, ámbar si bajo).
class PlatePainter extends CustomPainter {
  final PlateBuilder builder;
  final bool cheatDayActive;

  PlatePainter({required this.builder, this.cheatDayActive = false});

  static const Color _emptyBg = Color(0xFF0F1B2C);
  static const Color _border = Color(0x1AFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;

    final bgPaint = Paint()
      ..color = _emptyBg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final borderPaint = Paint()
      ..color = _border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, borderPaint);

    final total = builder.totalSlots;
    if (total == 0) {
      _drawEmptyHint(canvas, center);
      return;
    }

    const categoriesInOrder = [
      FoodCategory.protein,
      FoodCategory.fat,
      FoodCategory.carb,
    ];

    double startAngle = -math.pi / 2;
    for (final category in categoriesInOrder) {
      final slots = builder.slotsForCategory(category);
      if (slots == 0) continue;
      final sweep = (slots / total) * 2 * math.pi;
      final color = _colorForScore(
        builder.qualityScoreForCategory(category),
      );
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      _drawCategoryLabel(canvas, center, radius, startAngle, sweep, category);
      startAngle += sweep;
    }

    _drawSectorDividers(canvas, center, radius, total, categoriesInOrder);
  }

  /// Mapea un score 0-100 a un color (rojo → ámbar → verde).
  static Color _colorForScore(int score) {
    if (score >= 85) return const Color(0xFF10B981); // verde fuerte
    if (score >= 70) return const Color(0xFF34D399); // verde claro
    if (score >= 50) return const Color(0xFFFBBF24); // amarillo
    if (score >= 30) return const Color(0xFFF59E0B); // ámbar
    return const Color(0xFFEF4444); // rojo
  }

  void _drawCategoryLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweep,
    FoodCategory category,
  ) {
    final mid = startAngle + sweep / 2;
    final labelRadius = radius * 0.65;
    final labelOffset = Offset(
      center.dx + labelRadius * math.cos(mid),
      center.dy + labelRadius * math.sin(mid),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: category.label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF052E1A),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final pos = Offset(
      labelOffset.dx - textPainter.width / 2,
      labelOffset.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, pos);
  }

  void _drawSectorDividers(
    Canvas canvas,
    Offset center,
    double radius,
    int total,
    List<FoodCategory> categoriesInOrder,
  ) {
    final dividerPaint = Paint()
      ..color = const Color(0xFF0C1422)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double angle = -math.pi / 2;
    for (final cat in categoriesInOrder) {
      final slots = builder.slotsForCategory(cat);
      if (slots == 0) continue;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, dividerPaint);
      angle += (slots / total) * 2 * math.pi;
    }
  }

  void _drawEmptyHint(Canvas canvas, Offset center) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Plato vacío',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant PlatePainter oldDelegate) =>
      oldDelegate.builder.itemCount != builder.itemCount ||
      oldDelegate.builder.totalSlots != builder.totalSlots ||
      oldDelegate.builder.qualityPercent != builder.qualityPercent ||
      oldDelegate.cheatDayActive != cheatDayActive;
}

// ── Sub-widgets ───────────────────────────────────────────────────────

class _QualityBadge extends StatelessWidget {
  final PlateQuality quality;
  final String? tip;

  const _QualityBadge({required this.quality, required this.tip});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(quality);
    final icon = _iconFor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  quality.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 6),
            Text(
              tip!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorFor(PlateQuality q) => switch (q) {
        PlateQuality.excellent => AppColors.statusGood,
        PlateQuality.good => AppColors.accent,
        PlateQuality.needsWork => AppColors.statusWarn,
        PlateQuality.cheatDay => AppColors.textSecondary,
      };

  IconData _iconFor(PlateQuality q) => switch (q) {
        PlateQuality.excellent => Icons.verified_rounded,
        PlateQuality.good => Icons.thumb_up_rounded,
        PlateQuality.needsWork => Icons.lightbulb_rounded,
        PlateQuality.cheatDay => Icons.celebration_rounded,
      };
}

class _SelectedChips extends StatelessWidget {
  final PlateBuilder builder;
  final void Function(Food food) onRemove;

  const _SelectedChips({required this.builder, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: builder.items.map((f) {
        final color = PlatePainter._colorForScore(f.qualityScore);
        return InkWell(
          onTap: () => onRemove(f),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.name,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.close, size: 12, color: color),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar alimento (pollo, aguacate, arroz...)',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Food> results;
  final void Function(Food food) onPick;

  const _SearchResults({required this.results, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: results.map((f) {
          final color = PlatePainter._colorForScore(f.qualityScore);
          return InkWell(
            onTap: () => onPick(f),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderSubtle.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      f.category.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.add_circle_outline,
                      color: AppColors.accent, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MealTimeRow extends StatelessWidget {
  final DateTime mealTime;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<TimeOfDay> onTimePicked;

  const _MealTimeRow({
    required this.mealTime,
    required this.expanded,
    required this.onToggle,
    required this.onTimePicked,
  });

  String _format(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(mealTime),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.metabolicGreen,
                surface: AppColors.bgElevated,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onTimePicked(picked);
        onToggle();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Hora del plato',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _format(mealTime),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.edit_outlined,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheatDayToggle extends StatelessWidget {
  final CheatDayState cheatDay;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _CheatDayToggle({
    required this.cheatDay,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final active = cheatDay.isActiveToday;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.statusWarn : AppColors.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.celebration : Icons.celebration_outlined,
            color: active ? AppColors.statusWarn : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Hoy es mi día de permitidos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: active,
            activeColor: AppColors.statusWarn,
            onChanged: (v) {
              if (v) {
                onActivate();
              } else {
                onDeactivate();
              }
            },
          ),
        ],
      ),
    );
  }
}
