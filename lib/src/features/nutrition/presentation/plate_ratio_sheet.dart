// SPEC-137 E.3: sheet de registro del pilar Nutrición — plato armable.
//
// REEMPLAZA la versión de E.1 (5 cards de proporción A:E rejected por
// abstracta). El nuevo paradigma: el usuario CONSTRUYE el plato
// seleccionando alimentos del catálogo curado (FoodCatalog). El círculo
// central refleja en tiempo real la composición (Proteína / Grasa /
// Carbos) coloreada por calidad metabólica (verde = A, ámbar = E).
//
// Bajo el plato, un badge cualitativo: "Excelente plato" / "Buen plato"
// / "Plato mejorable" / "Día de permitidos", más un tip accionable
// ("Cambiá el arroz por brócoli y subís a Excelente").
//
// IMPORTANTE: el usuario nunca ve "% A" ni "2 a 1" en pantalla. Esos
// conceptos viven internamente para persistir el `MealRatio` derivado
// que alimenta el Cociente A del IMR.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/plate_builder.dart';

class PlateRatioSheet extends ConsumerStatefulWidget {
  /// Etiqueta semántica del plato. Si es null, el notifier usa el
  /// label sugerido según la hora del día.
  final String? label;

  /// Timestamp del plato. Si es null, ahora.
  final DateTime? mealTime;

  const PlateRatioSheet({
    super.key,
    this.label,
    this.mealTime,
  });

  static Future<void> show(
    BuildContext context, {
    String? label,
    DateTime? mealTime,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlateRatioSheet(label: label, mealTime: mealTime),
    );
  }

  @override
  ConsumerState<PlateRatioSheet> createState() => _PlateRatioSheetState();
}

class _PlateRatioSheetState extends ConsumerState<PlateRatioSheet> {
  final PlateBuilder _builder = PlateBuilder();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final cheatDay = ref.watch(cheatDayProvider);
    final cheatActive = cheatDay.isActiveToday;
    final quality = _builder.quality(cheatDayActive: cheatActive);
    final tip = _builder.tip(cheatDayActive: cheatActive);

    final mediaPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaPadding),
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
              Text(
                'Tocá lo que comiste. El plato te dice qué tan sano fue.',
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
                    painter: PlatePainter(builder: _builder),
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
              const Text(
                'AGREGAR ALIMENTO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _CategoryGrid(onPick: _openPicker),
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
                  onPressed: _builder.isEmpty || _submitting ? null : _submit,
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

  Future<void> _openPicker(FoodCategory category) async {
    final picked = await showModalBottomSheet<Food>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FoodPicker(category: category),
    );
    if (picked != null && mounted) {
      setState(() => _builder.add(picked));
    }
  }

  Future<void> _submit() async {
    if (_builder.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final isCheatDay = ref.read(cheatDayProvider).isActiveToday;
      await ref.read(nutritionProvider.notifier).logMeal(
            label: widget.label,
            mealTime: widget.mealTime,
            ratio: _builder.derivedMealRatio,
            isCheatDay: isCheatDay,
          );
      if (mounted) Navigator.of(context).pop();
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

// ── Painter del círculo central ───────────────────────────────────────

/// Dibuja el plato sólido con sectores proporcionales a la composición
/// del PlateBuilder. El color de cada sector refleja la calidad
/// metabólica de los alimentos de esa categoría.
class PlatePainter extends CustomPainter {
  final PlateBuilder builder;

  PlatePainter({required this.builder});

  static const Color _emptyBg = Color(0xFF0F1B2C);
  static const Color _border = Color(0x1AFFFFFF);
  static const Color _qualityA = Color(0xFF10B981);
  static const Color _qualityE = Color(0xFFF59E0B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // Fondo (plato vacío).
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
      _drawEmptyHint(canvas, center, radius);
      return;
    }

    // Dibujar sectores en orden fijo (Proteína → Grasa → Carbos) para
    // que el usuario aprenda dónde queda cada categoría.
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
      final color = _colorForCategory(category);

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

      _drawCategoryLabel(
        canvas,
        center,
        radius,
        startAngle,
        sweep,
        category,
      );

      startAngle += sweep;
    }

    // Línea sutil entre sectores para distinguirlos sin agresividad.
    _drawSectorDividers(canvas, center, radius, total, categoriesInOrder);
  }

  Color _colorForCategory(FoodCategory category) {
    final totalSlots = builder.slotsForCategory(category);
    if (totalSlots == 0) return _emptyBg;
    final aSlots = builder.qualityASlotsForCategory(category);
    final aFraction = aSlots / totalSlots;
    // Si todos los alimentos de la categoría son A → verde puro.
    // Si todos son E → ámbar puro.
    // Si mezclado → interpolación lineal.
    return Color.lerp(_qualityE, _qualityA, aFraction) ?? _qualityA;
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
        style: TextStyle(
          color: const Color(0xFF052E1A),
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

  void _drawEmptyHint(Canvas canvas, Offset center, double radius) {
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
      oldDelegate.builder.totalSlots != builder.totalSlots;
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
        final accent = f.quality == FoodQuality.typeA
            ? AppColors.statusGood
            : AppColors.statusWarn;
        return InkWell(
          onTap: () => onRemove(f),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.name,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.close, size: 12, color: accent),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final void Function(FoodCategory category) onPick;

  const _CategoryGrid({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CategoryButton(
            category: FoodCategory.protein,
            icon: Icons.set_meal_outlined,
            color: AppColors.statusGood,
            onTap: () => onPick(FoodCategory.protein),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryButton(
            category: FoodCategory.fat,
            icon: Icons.water_drop_outlined,
            color: AppColors.statusGood,
            onTap: () => onPick(FoodCategory.fat),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CategoryButton(
            category: FoodCategory.carb,
            icon: Icons.bakery_dining_outlined,
            color: AppColors.statusWarn,
            onTap: () => onPick(FoodCategory.carb),
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final FoodCategory category;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.category,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                category.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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

// ── Picker secundario de alimentos por categoría ──────────────────────

class _FoodPicker extends StatelessWidget {
  final FoodCategory category;
  const _FoodPicker({required this.category});

  @override
  Widget build(BuildContext context) {
    final items = FoodCatalog.byCategory(category);
    final mediaPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: mediaPadding),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Elegí un ${category.label.toLowerCase()}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((f) {
                  final accent = f.quality == FoodQuality.typeA
                      ? AppColors.statusGood
                      : AppColors.statusWarn;
                  return Material(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(f),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          f.name,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
