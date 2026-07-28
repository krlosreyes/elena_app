import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_icons.dart';

/// SPEC-168.0.B + SPEC-168.0.A v2 (Opción B, Carlos 2026-06-03):
/// card de "Mis objetivos" que lista **todos** los goals del usuario
/// (activos + inactivos) con CTA a /goals/setup. Los inactivos se
/// renderizan atenuados con badge "Sin activar". El estado vacío
/// solo aparece cuando el usuario nunca pasó por el step 5 del
/// onboarding (caso legacy pre-SPEC-168) ni configuró desde Perfil.
///
/// SPEC-119: extraído de `_buildGoalsSection` + `_buildGoalsEmptyState`
/// + `_buildGoalsListCard` + `_buildGoalRow` + `_formatGoalValue` en
/// `profile_screen.dart` (ARCH-03). `ref.watch(goalsProvider)` ya
/// devuelve el mapa completo de goals — se consume entero (`.values`)
/// así que no aplica `.select()` de un campo puntual.
class ProfileGoalsSection extends ConsumerWidget {
  const ProfileGoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsMap = ref.watch(goalsProvider);
    final allGoals = goalsMap.values.toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    if (allGoals.isEmpty) {
      return _buildGoalsEmptyState(context);
    }
    return _buildGoalsListCard(context, allGoals);
  }

  /// Estado vacío: usuario que omitió onboarding o legacy pre-SPEC-168.
  /// Invita a configurar con narrativa coaching ("Elena tiene
  /// recomendaciones listas").
  Widget _buildGoalsEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no configuraste tus objetivos.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elena tiene recomendaciones listas basadas en tus datos.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/goals/setup'),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Configurar objetivos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.metabolicGreen,
                side: BorderSide(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card con lista de goals (activos + inactivos) + CTA "Editar
  /// objetivos" en footer. Sigue el patrón de `ProfileProtocolCard`
  /// (header + filas + divisor + InkWell de acción al fondo).
  Widget _buildGoalsListCard(
    BuildContext context,
    List<UserGoal> allGoals,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < allGoals.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: AppColors.borderSubtle,
              ),
            _buildGoalRow(allGoals[i]),
          ],
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.borderSubtle,
          ),
          InkWell(
            onTap: () => context.push('/goals/setup'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Editar objetivos',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.metabolicGreen.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila individual de un goal: emoji + label + valor + unit en línea.
  /// SPEC-168.0.A v2 Opción B: si el goal está inactivo, atenuamos el
  /// row con opacidad reducida y agregamos badge "Sin activar" en
  /// lugar de la unidad. El usuario tap "Editar objetivos" para
  /// activar o ajustar.
  Widget _buildGoalRow(UserGoal goal) {
    final double opacity = goal.isActive ? 1.0 : 0.45;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(goalIcon(goal.type),
                      size: 16, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      goal.label,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (goal.isActive)
              Text(
                '${_formatGoalValue(goal)} ${goal.unit}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_formatGoalValue(goal)} ${goal.unit}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sin activar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Formateo del valor numérico del goal: enteros sin decimales,
  /// fracciones con 1 decimal. Coherente con la presentación en
  /// `goalsProgressDashboard`.
  String _formatGoalValue(UserGoal goal) {
    final v = goal.targetValue;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
