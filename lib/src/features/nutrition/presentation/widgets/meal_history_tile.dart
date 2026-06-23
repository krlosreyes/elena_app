// SPEC-240: tile individual dentro de MealHistorySheet.
//
// Muestra la información de una comida del Día Metabólico activo y expone
// las acciones Editar y Eliminar. La eliminación usa confirmación INLINE
// (sin dialog Modal adicional) para reducir fricción:
//
//   Estado normal  → botones [Editar] [Eliminar]
//   Confirmando    → botones [Cancelar] [◉ Confirmar]
//
// El estado `_confirmingDelete` es local al Widget para no contaminar el
// provider global con lógica puramente de UI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/presentation/plate_ratio_sheet.dart';

class MealHistoryTile extends ConsumerStatefulWidget {
  const MealHistoryTile({
    super.key,
    required this.log,
    required this.accent,
  });

  final NutritionLog log;
  final Color accent;

  @override
  ConsumerState<MealHistoryTile> createState() => _MealHistoryTileState();
}

class _MealHistoryTileState extends ConsumerState<MealHistoryTile> {
  bool _confirmingDelete = false;

  // ── helpers ────────────────────────────────────────────────────────────

  Color _ratioColor(MealRatio ratio) => switch (ratio) {
        MealRatio.allA || MealRatio.a3e1 => AppColors.statusGood,
        MealRatio.a2e1 => AppColors.accent,
        MealRatio.a1e1 => AppColors.statusWarn,
        MealRatio.allE => AppColors.statusBad,
      };

  /// Nombres de alimentos del log (desde FoodCatalog). Si plateItemIds está
  /// vacío (logs pre-SPEC-BUG6 o registros rápidos) devuelve lista vacía.
  List<String> _foodNames() {
    if (widget.log.plateItemIds.isEmpty) return const [];
    return widget.log.plateItemIds
        .map((id) => FoodCatalog.byId(id)?.name ?? id)
        .toList(growable: false);
  }

  String _formattedTime() =>
      DateFormat('HH:mm').format(widget.log.timestamp.toLocal());

  // ── acciones ───────────────────────────────────────────────────────────

  void _onEdit() {
    PlateRatioSheet.show(
      context,
      label: widget.log.label,
      initialMealTime: widget.log.timestamp,
      logToReplaceId: widget.log.id,
      initialPlateItemIds: widget.log.plateItemIds,
    );
  }

  void _onDeleteConfirmed() {
    ref.read(nutritionProvider.notifier).deleteMealById(widget.log.id);
    // No hace falta setState: el tile desaparecerá cuando MealHistorySheet
    // reconstruya la lista tras el cambio en nutritionProvider.
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final ratioColor = _ratioColor(log.ratio);
    final foodNames = _foodNames();
    final time = _formattedTime();
    final isOutOfWindow = !log.withinCircadianWindow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _confirmingDelete
              ? AppColors.statusBad.withValues(alpha: 0.35)
              : widget.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── fila superior: hora + label + ratio badge ─────────────────
          Row(
            children: [
              // Hora
              Text(
                time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              // Ícono fuera-de-ventana
              if (isOutOfWindow) ...[
                Icon(
                  Icons.schedule_outlined,
                  size: 13,
                  color: AppColors.statusWarn.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 4),
              ],
              // Etiqueta semántica
              Expanded(
                child: Text(
                  log.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge ratio
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ratioColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.ratio.label,
                  style: TextStyle(
                    color: ratioColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          // ── alimentos (solo si hay plateItemIds) ──────────────────────
          if (foodNames.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              foodNames.join(' · '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── aviso fuera de ventana ────────────────────────────────────
          if (isOutOfWindow) ...[
            const SizedBox(height: 5),
            Text(
              'Fuera de ventana circadiana',
              style: TextStyle(
                color: AppColors.statusWarn.withValues(alpha: 0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── botones de acción ─────────────────────────────────────────
          if (_confirmingDelete)
            _ConfirmDeleteRow(
              onCancel: () => setState(() => _confirmingDelete = false),
              onConfirm: _onDeleteConfirmed,
            )
          else
            _ActionRow(
              onEdit: _onEdit,
              onDelete: () => setState(() => _confirmingDelete = true),
              accent: widget.accent,
            ),
        ],
      ),
    );
  }
}

// ── fila de acciones normales ──────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onEdit,
    required this.onDelete,
    required this.accent,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TileButton(
            label: 'Editar',
            icon: Icons.edit_outlined,
            color: accent,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TileButton(
            label: 'Eliminar',
            icon: Icons.delete_outline_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}

// ── fila de confirmación inline ────────────────────────────────────────────

class _ConfirmDeleteRow extends StatelessWidget {
  const _ConfirmDeleteRow({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TileButton(
            label: 'Cancelar',
            icon: Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            onPressed: onCancel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TileButton(
            label: 'Confirmar',
            icon: Icons.delete_forever_rounded,
            color: AppColors.statusBad,
            onPressed: onConfirm,
            filled: true,
          ),
        ),
      ],
    );
  }
}

// ── botón compacto reutilizable ────────────────────────────────────────────

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: color.withValues(alpha: 0.40)),
        ),
        icon: Icon(icon, size: 14),
        label: Text(label,
            style:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
