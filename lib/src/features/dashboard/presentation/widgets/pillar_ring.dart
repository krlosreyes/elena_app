// SPEC-66 v2: PillarRing — anillo circular interactivo de un pilar.
//
// Extraído como widget público desde dashboard_screen.dart para hacerlo
// testeable con widget tests (ScopedFunc no requiere mocks de Riverpod).
// Mantiene la misma firma y comportamiento que tenía como método privado
// `_pillarRing(...)`.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Anillo circular de progreso para un pilar metabólico (Ayuno, Sueño,
/// Hidratación, Ejercicio, Comidas). Muestra:
/// - Anillo de progreso con `progress` (0.0–1.0).
/// - Ícono central con el `color` del pilar.
/// - Glow visual cuando `isSelected` es true.
/// - Check verde cuando `completed` es true.
/// - Label debajo, saturado si seleccionado.
class PillarRing extends StatelessWidget {
  const PillarRing({
    super.key,
    required this.icon,
    required this.color,
    required this.progress,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.completed = false,
  });

  final IconData icon;
  final Color color;
  final double progress;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(icon, color: color, size: 22),
                if (completed)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.metabolicGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? color : Colors.white.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
