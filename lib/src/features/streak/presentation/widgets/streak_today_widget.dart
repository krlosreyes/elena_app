// Propuesta "racha protagonista" (2026-07-15, P1+P2): la racha vivía solo
// en Análisis/Progreso — invisible en el Dashboard, la pantalla que el
// usuario abre a diario. `dashboard_screen.dart` no referenciaba
// `streakProvider` en absoluto. Este widget trae la racha al frente (P1,
// mismo lugar donde Duolingo muestra su llama) y muestra el estado de HOY
// con la razón explícita cuando el día aún no califica (P2) — complementa
// (no reemplaza) el punto sutil de 12px en los rings de Ayuno/Sueño
// (SPEC-255 RF-07), que sigue existiendo como refuerzo secundario en el
// lugar donde ocurre la acción.
//
// El texto de "por qué" usa `StreakEntry.missReason` — fuente única
// compartida con el mensaje de racha rota (P3) y el detalle del histórico
// (P5), para que ningún lugar de la app pueda contradecir a otro sobre
// la misma regla.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/presentation/widgets/streak_explainer_sheet.dart';

class StreakTodayWidget extends ConsumerWidget {
  const StreakTodayWidget({super.key});

  static const _flameActive = Color(0xFFF97316);
  static const _qualifiedGreen = Color(0xFF34D399);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final current = streak.currentStreak;
    final todayEntry = streak.todayEntry;
    final todayQualifies = todayEntry?.qualifiesForStreak ?? false;

    final Color flameColor =
        current > 0 ? _flameActive : Colors.white.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () => showStreakExplainerSheet(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: flameColor.withValues(alpha: current > 0 ? 0.35 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: flameColor,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current == 0
                        ? 'Sin racha activa'
                        : '$current ${current == 1 ? "día" : "días"} de racha',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _todayStatusText(todayEntry, todayQualifies),
                    style: TextStyle(
                      color: todayQualifies
                          ? _qualifiedGreen
                          : Colors.white.withValues(alpha: 0.60),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.30),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// P2: estado de HOY explícito, con la razón real cuando el día aún no
  /// califica — construido desde `StreakEntry.missReason` (ver
  /// streak_entry.dart), no una lectura propia de la regla.
  String _todayStatusText(StreakEntry? todayEntry, bool qualifies) {
    if (qualifies) return 'Hoy ya cuenta para tu racha';

    final reason = todayEntry?.missReason;
    if (reason == null) {
      // Sin entry todavía (app recién abierta, ningún pilar evaluado hoy).
      return 'Te faltan 3 pilares para que hoy cuente';
    }
    if (reason.isAnchorIssue) {
      return 'Te falta ayuno o sueño para que hoy cuente';
    }
    final n = reason.missingPillarsCount!;
    return n == 1
        ? 'Te falta 1 pilar más para que hoy cuente'
        : 'Te faltan $n pilares más para que hoy cuente';
  }
}
