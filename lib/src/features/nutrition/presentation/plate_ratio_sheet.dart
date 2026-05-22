// SPEC-137 §RF-137-10: sheet de registro del pilar Nutrición.
//
// Patrón coherente con `protocol_selector_sheet.dart` (SPEC-98): modal
// bottom sheet con lista vertical de cards apilables. Cero sliders
// continuos, cero swipe gestures, cero scanner IA. El usuario clasifica
// el plato en una de 5 posiciones del enum MealRatio.
//
// Flujo de 3 toques:
// 1. Abrir desde la tarjeta de Hoy.
// 2. Tap en la card de proporción (preseleccionada según nervousSystem).
// 3. Tap en "Registrar plato".
//
// El toggle del día de permitidos vive arriba del botón primario.
// Activarlo marca todos los logs futuros del día como isCheatDay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Metadata visual por proporción A:E. Subtitulo orienta sin
/// prescribir y sin lenguaje clínico (cumple NUTRITION_BIBLIOGRAPHY §11).
class _RatioVisual {
  final MealRatio ratio;
  final Color accent;
  final IconData icon;
  final String subtitle;

  const _RatioVisual({
    required this.ratio,
    required this.accent,
    required this.icon,
    required this.subtitle,
  });
}

const List<_RatioVisual> _kRatios = [
  _RatioVisual(
    ratio: MealRatio.allA,
    accent: AppColors.statusGood,
    icon: Icons.eco_outlined,
    subtitle: 'Solo verdes, proteína y grasa saludable',
  ),
  _RatioVisual(
    ratio: MealRatio.a3e1,
    accent: AppColors.statusGood,
    icon: Icons.spa_outlined,
    subtitle: '3 partes A · 1 parte E. Recomendado para pérdida',
  ),
  _RatioVisual(
    ratio: MealRatio.a2e1,
    accent: AppColors.accent,
    icon: Icons.restaurant_outlined,
    subtitle: '2 partes A · 1 parte E. Mantenimiento estándar',
  ),
  _RatioVisual(
    ratio: MealRatio.a1e1,
    accent: AppColors.statusWarn,
    icon: Icons.balance_outlined,
    subtitle: 'Mitad y mitad. Fuera del rango sostenible',
  ),
  _RatioVisual(
    ratio: MealRatio.allE,
    accent: AppColors.statusBad,
    icon: Icons.cake_outlined,
    subtitle: 'Solo harinas, dulces o lácteos. Día de permitidos',
  ),
];

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

  /// Helper estático para abrir la sheet desde cualquier callsite.
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
  MealRatio? _selected;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final cheatDay = ref.watch(cheatDayProvider);

    final ns = user == null
        ? NervousSystem.unknown
        : NervousSystem.fromPersistenceKey(user.nervousSystem);
    final suggested = ns.suggestedRatio;
    _selected ??= suggested;

    final mediaPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: mediaPadding),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              Text(
                'Registrar plato',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '¿Qué proporción de Tipo A vs Tipo E predominó?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),
              ..._kRatios.map(
                (v) => _RatioCard(
                  visual: v,
                  isSelected: _selected == v.ratio,
                  isSuggested: suggested == v.ratio,
                  onTap: () => setState(() => _selected = v.ratio),
                ),
              ),
              const SizedBox(height: 12),
              _CheatDayToggle(
                cheatDay: cheatDay,
                onActivate: _handleCheatDayActivate,
                onDeactivate: _handleCheatDayDeactivate,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.metabolicGreen,
                    foregroundColor: AppColors.bgBase,
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

  Future<void> _submit() async {
    final ratio = _selected;
    if (ratio == null) return;
    setState(() => _submitting = true);
    try {
      final isCheatDay = ref.read(cheatDayProvider).isActiveToday;
      await ref.read(nutritionProvider.notifier).logMeal(
            label: widget.label,
            mealTime: widget.mealTime,
            ratio: ratio,
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
            content: Text('Día de permitidos activo. Disfrutalo, sin culpa.'),
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

class _RatioCard extends StatelessWidget {
  final _RatioVisual visual;
  final bool isSelected;
  final bool isSuggested;
  final VoidCallback onTap;

  const _RatioCard({
    required this.visual,
    required this.isSelected,
    required this.isSuggested,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = visual.accent;
    final bg = isSelected
        ? accent.withValues(alpha: 0.16)
        : AppColors.bgElevated;
    final border = isSelected ? accent : AppColors.borderDefault;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(visual.icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            visual.ratio.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (isSuggested) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Recomendado',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        visual.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
