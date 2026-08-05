// SPEC-262: la economía de gamificación (estrellas, congeladores, ayuno de
// por vida, nivel y Tienda).
//
// SPEC-263 (5-ago-2026): dejó de ser una pantalla propia ("Tus estadísticas")
// que se enlazaba con "Tu racha". Ahora su contenido se EMBEBE dentro de "Tu
// racha" (racha_detail_screen.dart) como `GamificationStatsBody`, para que
// todo el estado del hábito viva en UNA sola pantalla coherente en vez de dos
// que rebotaban entre sí. Todo lo que se muestra es REAL y persistido.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/gamification/application/gamification_notifier.dart';
import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';
import 'package:elena_app/src/features/gamification/domain/shop_item.dart';

const Color _gold = Color(0xFFF59E0B); // estrellas
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
                label: 'ESTRELLAS',
                value: '${s.stars}',
                icon: Icons.star_rounded,
                color: _gold,
                onInfo: () => _showInfo(context, _InfoTopic.estrellas),
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
        _sectionTitle('TIENDA'),
        const SizedBox(height: 8),
        _shopHint(),
        const SizedBox(height: 10),
        ...Shop.items.map((it) => _ShopRow(item: it, state: s)),
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

class _ShopRow extends ConsumerWidget {
  const _ShopRow({required this.item, required this.state});
  final ShopItem item;
  final GamificationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final affordable = state.canAfford(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit_rounded, color: _ice, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Opacity(
            opacity: affordable ? 1 : 0.4,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final ok =
                    ref.read(gamificationProvider.notifier).buyFrosty(item);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? '¡Listo! +${item.frostyQty} '
                            '${item.frostyQty == 1 ? "congelador" : "congeladores"}'
                        : 'Te faltan estrellas para este paquete.'),
                    backgroundColor: ok ? AppColors.metabolicGreen : _gold,
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: _gold, size: 16),
                    const SizedBox(width: 6),
                    Text('${item.starCost}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
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

Widget _shopHint() => const Text(
      'Canjea las estrellas que ganas registrando tus hábitos por '
      'congeladores que protegen tu racha.',
      style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
    );

enum _InfoTopic { estrellas, congeladores, nivel }

void _showInfo(BuildContext context, _InfoTopic topic) {
  final (title, body) = switch (topic) {
    _InfoTopic.estrellas => (
        'Estrellas',
        'Ganas estrellas cada vez que registras un hábito saludable: tomar '
            'agua, una comida, cerrar tu ayuno, y más. Son una moneda: '
            'canjéalas en la Tienda por congeladores. No se compran con dinero '
            'ni se pueden farmear — cada estrella nace de algo que hiciste de '
            'verdad.'
      ),
    _InfoTopic.congeladores => (
        'Congeladores',
        'Un congelador protege tu racha un día que no llegues al mínimo. Ganas '
            'uno gratis cada 6 días que califican, o los canjeas con estrellas '
            'en la Tienda. Guárdalos para cuando de verdad los necesites.'
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
