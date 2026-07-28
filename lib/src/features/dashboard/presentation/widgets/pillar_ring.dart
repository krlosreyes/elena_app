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
/// - SPEC-140.1: porcentaje opcional bajo el label (líneas 2 si `showPercent`).
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
    this.showPercent = false,
    this.isStreakAnchor = false,
    this.isRestDay = false,
  });

  final IconData icon;
  final Color color;
  final double progress;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool completed;

  /// SPEC-257 §3.1: true cuando hoy es un día de descanso PROGRAMADO
  /// (nivel Novato, 12:12/14:10 con frecuencia semanal reducida — ver
  /// `FastingSchedule`). El anillo se muestra cubierto (100%) pero con
  /// una insignia distinta al check verde de "completado": Ayuno es
  /// pilar-ancla (SPEC-255 RF-07) y pintar un descanso idéntico a un
  /// ayuno real falsearía el histórico. Solo aplica al ring de Ayuno.
  final bool isRestDay;

  /// SPEC-140.1: si true, renderiza el % del progreso como segunda línea
  /// bajo el label. Permite que el usuario vea el peso individual de
  /// cada pilar sin necesidad de tocarlo. El % se redondea al entero
  /// más cercano y se clampea a [0, 100].
  final bool showPercent;

  /// SPEC-255 RF-07: true cuando este pilar (ayuno o sueño) es el ancla
  /// que aún falta hoy para calificar para la racha (regla "3/5 con
  /// ayuno o sueño"). Muestra una marca sutil — no es un estado de error,
  /// solo una pista de qué pilar mueve más la aguja hoy.
  final bool isStreakAnchor;

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
                // SPEC-255 RF-07: pista de pilar-ancla — solo mientras no
                // esté completado (una vez el check verde aparece, la
                // pista ya no aporta nada).
                if (isStreakAnchor && !completed)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                if (isRestDay)
                  // SPEC-257 §3.1: insignia distinta de "completado" —
                  // gris/luna en vez de check verde, para no falsear el
                  // histórico de un pilar-ancla.
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bedtime_rounded,
                        color: Color(0xFF1E293B),
                        size: 10,
                      ),
                    ),
                  )
                else if (completed)
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
          if (showPercent) ...[
            const SizedBox(height: 2),
            Text(
              '${(progress.clamp(0.0, 1.0) * 100).round()}%',
              style: TextStyle(
                fontSize: 10,
                color:
                    isSelected ? color : Colors.white.withValues(alpha: 0.45),
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
