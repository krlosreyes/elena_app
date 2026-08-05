// SPEC-262 / SPEC-264: la economía de gamificación (perlas, congeladores, ayuno
// de por vida y nivel).
//
// SPEC-263: se embebe dentro de "Tu racha" como `GamificationStatsBody`.
// SPEC-264: "estrellas" pasa a llamarse "perlas" DE CARA AL USUARIO (las claves
// persistidas en Firestore siguen siendo `stars`/`totalStarsEarned` para no
// romper datos). Las perlas ya NO compran congeladores: los congeladores se
// ganan solo por constancia (1 cada 6 días que califican) y las perlas se usan
// para animar a los rivales en los Retos (zumbidos). Por eso la "Tienda" deja
// de vender y pasa a explicar la economía.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/gamification/application/gamification_notifier.dart';
import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';

const Color _pearl = Color(0xFFD8B4E2); // perlas (nácar lila)
const Color _ice = Color(0xFF60A5FA); // congeladores

/// Bloque embebible con la economía de gamificación. Se monta dentro de "Tu
/// racha" (no tiene Scaffold propio); asume vivir en un ListView con padding.
class GamificationStatsBody extends ConsumerWidget {
  const GamificationStatsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gamificationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'PERLAS',
                value: '${s.stars}',
                icon: Icons.blur_circular_rounded,
                color: _pearl,
                onInfo: () => _showInfo(context, _InfoTopic.perlas),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'CONGELADORES',
                value: '${s.frosties}',
                icon: Icons.ac_unit_rounded,
                color: _ice,
                onInfo: () => _showInfo(context, _InfoTopic.congeladores),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FastingCard(hours: s.lifetimeFastingHours),
        const SizedBox(height: 12),
        _LevelCard(
            state: s, onInfo: () => _showInfo(context, _InfoTopic.nivel)),
        const SizedBox(height: 24),
        _sectionTitle('CÓMO FUNCIONA LA ECONOMÍA'),
        const SizedBox(height: 8),
        _economyHint(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onInfo,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
              GestureDetector(
                onTap: onInfo,
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FastingCard extends StatelessWidget {
  const _FastingCard({required this.hours});
  final double hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.metabolicGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AYUNANDO',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text('${hours.toStringAsFixed(0)} horas de por vida',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.state, required this.onInfo});
  final GamificationState state;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final info = state.levelInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.metabolicGreen.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('NIVEL',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
              GestureDetector(
                onTap: onInfo,
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.metabolicGreen, size: 24),
              const SizedBox(width: 8),
              Text('${info.level}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(info.title,
                    style: const TextStyle(
                        color: AppColors.metabolicGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Text('${info.totalXp} XP',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.metabolicGreen),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            info.xpForNext <= 0
                ? 'Nivel máximo'
                : 'Faltan ${info.xpForNext - info.xpIntoLevel} XP para el nivel ${info.level + 1}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String t) => Text(
      t,
      style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5),
    );

Widget _economyHint() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EconomyRow(
            icon: Icons.blur_circular_rounded,
            color: _pearl,
            text: 'Ganas perlas registrando tus hábitos. Se usan para animar '
                'a tus rivales en los Retos (zumbidos, porras).',
          ),
          SizedBox(height: 12),
          _EconomyRow(
            icon: Icons.ac_unit_rounded,
            color: _ice,
            text: 'Los congeladores protegen tu racha. Se ganan siendo '
                'constante: 1 cada 6 días que cumples. No se compran.',
          ),
        ],
      ),
    );

class _EconomyRow extends StatelessWidget {
  const _EconomyRow(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }
}

enum _InfoTopic { perlas, congeladores, nivel }

void _showInfo(BuildContext context, _InfoTopic topic) {
  final (title, body) = switch (topic) {
    _InfoTopic.perlas => (
        'Perlas',
        'Ganas perlas cada vez que registras un hábito saludable: tomar agua, '
            'una comida, cerrar tu ayuno, y más. Son la moneda social de Elena: '
            'se usan para animar a tus rivales en los Retos (zumbidos, porras). '
            'No se compran con dinero ni se pueden farmear — cada perla nace de '
            'algo que hiciste de verdad.'
      ),
    _InfoTopic.congeladores => (
        'Congeladores',
        'Un congelador protege tu racha un día que no llegues al mínimo. Se '
            'ganan solo siendo constante: 1 gratis cada 6 días que califican. '
            'No se compran — son un reflejo de tu constancia, no de tu saldo.'
      ),
    _InfoTopic.nivel => (
        'Nivel y XP',
        'Cada acción registrada suma XP y hace crecer tu nivel. El nivel es un '
            'reflejo real de tu constancia acumulada — no se puede comprar. '
            'Cada nivel exige un poco más de XP que el anterior.'
      ),
  };
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(body,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido',
                  style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}
