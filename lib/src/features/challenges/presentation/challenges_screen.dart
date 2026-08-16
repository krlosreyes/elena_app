// SPEC-263/264 + SPEC-299: "Retos" — competencia social sana por CONSTANCIA.
//
// SPEC-299 (rediseño): pantalla moderna y motivadora. Hero que explica de qué
// va el reto, tarjeta de PERLAS que por fin explica la moneda (qué es, cómo se
// gana, para qué sirve), y tarjetas de reto con un mini-tablero VIVO (avatar de
// cada rival, tu posición, puntos y progreso del período) en vez de una fila
// muerta. El puntaje es días que califican para la racha — se premia el hábito.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/challenges/application/challenge_controller.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/features/challenges/presentation/widgets/challenge_avatar.dart';
import 'package:elena_app/src/features/gamification/application/gamification_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const Color _accent = AppColors.accent;
const Color _perla = Color(0xFFD8B4E2);
const Color _gold = Color(0xFFF59E0B);

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(myChallengesProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Retos',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: false,
        actions: const [_PerlasPill(), SizedBox(width: 12)],
      ),
      bottomNavigationBar: const DashboardBottomNav(),
      body: SafeArea(
        child: challengesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _accent),
          ),
          error: (_, __) => _errorState(),
          data: (challenges) {
            final sorted = [...challenges]
              ..sort((a, b) => b.startDateKey.compareTo(a.startDateKey));
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                const _HeroCard(),
                const SizedBox(height: 12),
                const _PerlasCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Crear reto',
                        icon: Icons.add_rounded,
                        filled: true,
                        onTap: () => _openCreateSheet(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Unirme',
                        icon: Icons.group_add_rounded,
                        filled: false,
                        onTap: () => _openJoinSheet(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (sorted.isEmpty)
                  _emptyState()
                else ...[
                  const _SectionLabel('EN CURSO'),
                  const SizedBox(height: 10),
                  ...sorted.map((c) => _ChallengeCard(challenge: c)),
                ],
                const SizedBox(height: 20),
                const _ReceiveNudgesToggle(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Icon(Icons.groups_2_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 56),
            const SizedBox(height: 12),
            const Text(
              'Reta a alguien esta semana',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea un reto e invita con el código, o únete al de un amigo. '
              'La constancia se contagia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _errorState() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No pudimos cargar tus retos. Revisa tu conexión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateChallengeSheet(),
    );
  }

  void _openJoinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _JoinChallengeSheet(),
    );
  }
}

// ── Etiqueta de sección ─────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1),
      );
}

// ── Hero: de qué va el reto ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  static const _icons = [
    Icons.timer_rounded,
    Icons.fitness_center_rounded,
    Icons.restaurant_rounded,
    Icons.bedtime_rounded,
    Icons.water_drop_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _accent, size: 20),
              const SizedBox(width: 8),
              const Text('Compites por constancia',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Gana quien más días cierre sus 5 anillos en el período. No es la '
            'báscula: es sostener el hábito.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final ic in _icons)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.16),
                    ),
                    child: Icon(ic, size: 15, color: _accent),
                  ),
                ),
              const Spacer(),
              const Text('5 pilares = 5 anillos',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de PERLAS: saldo + qué son ──────────────────────────────────────
class _PerlasCard extends ConsumerWidget {
  const _PerlasCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perlas = ref.watch(gamificationProvider).stars;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPerlasHelp(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _perla.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _perla.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _perla.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.blur_on_rounded, color: _perla, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tienes $perlas perlas',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Text(
                    'Las ganas cumpliendo tus pilares. Gástalas en animar a tus '
                    'rivales y proteger tu racha.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: _perla),
          ],
        ),
      ),
    );
  }

  void _showPerlasHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.blur_on_rounded, color: _perla, size: 22),
                SizedBox(width: 8),
                Text('Qué son las perlas',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            SizedBox(height: 16),
            _PerlaHowRow(
              icon: Icons.check_circle_rounded,
              title: 'Las ganas cumpliendo',
              body: 'Cada pilar que cierras te da perlas: agua, comida, ayuno, '
                  'sueño y ejercicio. Nacen de lo que de verdad haces.',
            ),
            _PerlaHowRow(
              icon: Icons.waving_hand_rounded,
              title: 'Anima a tus rivales',
              body: 'Envía una porra o un zumbido en el tablero del reto. '
                  'Cuestan unas pocas perlas y llegan como buena onda.',
            ),
            _PerlaHowRow(
              icon: Icons.ac_unit_rounded,
              title: 'Protege tu racha',
              body: 'Cámbialas por congeladores: si un día no puedes cumplir, '
                  'un congelador evita que se rompa tu racha.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PerlaHowRow extends StatelessWidget {
  const _PerlaHowRow(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _perla, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Saldo de perlas en el AppBar ────────────────────────────────────────────
class _PerlasPill extends ConsumerWidget {
  const _PerlasPill();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perlas = ref.watch(gamificationProvider).stars;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: _perla.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _perla.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.blur_on_rounded, color: _perla, size: 15),
          const SizedBox(width: 6),
          Text('$perlas',
              style: const TextStyle(
                  color: _perla, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Tarjeta de un reto con mini-tablero vivo ────────────────────────────────
class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayKey = ChallengeScoring.dateKey(DateTime.now());
    final status = challenge.statusOn(todayKey);
    final (label, color) = switch (status) {
      ChallengeStatus.upcoming => ('Próximo', AppColors.textSecondary),
      ChallengeStatus.active => ('En curso', _accent),
      ChallengeStatus.ended => ('Terminado', _gold),
    };
    final myId = ref.watch(currentUserStreamProvider).valueOrNull?.id ?? '';
    final scoresAsync = ref.watch(challengeLeaderboardProvider(challenge.code));
    final (dayNum, total, frac) = _period(challenge);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/retos/${challenge.code}'),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(challenge.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    total > 0
                        ? 'Día $dayNum de $total'
                        : challenge.startDateKey,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const Spacer(),
                  Text('${challenge.memberCount} participantes',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 12),
              scoresAsync.maybeWhen(
                data: (scores) => _standings(scores, myId),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _standings(List<ChallengeScore> scores, String myId) {
    if (scores.isEmpty) {
      return const Text(
        'Aún no hay puntajes. En cuanto cada quien abra el reto, aparece aquí.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      );
    }
    final top = scores.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          _MiniRow(rank: i + 1, score: top[i], isMe: top[i].uid == myId),
        const SizedBox(height: 8),
        _motivation(scores, myId),
      ],
    );
  }

  Widget _motivation(List<ChallengeScore> scores, String myId) {
    final myIdx = scores.indexWhere((s) => s.uid == myId);
    String text;
    IconData icon = Icons.local_fire_department_rounded;
    if (myIdx < 0) {
      text = 'Abre el reto para publicar tu puntaje.';
      icon = Icons.info_outline_rounded;
    } else if (myIdx == 0) {
      final lead = scores.length > 1 ? scores[0].points - scores[1].points : 0;
      text = scores.length == 1
          ? 'Vas de primero. Invita con el código para competir.'
          : 'Vas 1º por $lead pts. Mantén el ritmo.';
    } else {
      final gap = scores[0].points - scores[myIdx].points;
      text =
          'Vas ${myIdx + 1}º, a $gap pts de la cabeza. Cierra un anillo más.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }

  static (int, int, double) _period(Challenge c) {
    final s = DateTime.tryParse(c.startDateKey);
    final e = DateTime.tryParse(c.endDateKey);
    if (s == null || e == null) return (0, 0, 0);
    final total = e.difference(s).inDays + 1;
    final dayNum = DateTime.now().difference(s).inDays + 1;
    final clamped = dayNum < 0 ? 0 : (dayNum > total ? total : dayNum);
    final frac = total > 0 ? clamped / total : 0.0;
    return (clamped, total, frac.toDouble());
  }
}

// ── Fila compacta del mini-tablero ──────────────────────────────────────────
class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.rank, required this.score, required this.isMe});
  final int rank;
  final ChallengeScore score;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => _gold,
      2 => const Color(0xFFCBD5E1),
      3 => const Color(0xFFB08D57),
      _ => AppColors.textSecondary,
    };
    final r = score.todayRings;
    final closed = [r.ayuno, r.ejercicio, r.nutricion, r.sueno, r.hidratacion];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? _accent.withValues(alpha: 0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isMe ? Border.all(color: _accent.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text('$rank',
                style: TextStyle(
                    color: medal, fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
          ChallengeAvatar(
            name: score.displayName,
            photoUrl: score.photoUrl,
            size: 30,
            highlight: isMe,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '${score.displayName} (tú)' : score.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: closed[i] ? _accent : Colors.transparent,
                            border: Border.all(
                              color: closed[i]
                                  ? _accent
                                  : AppColors.textSecondary
                                      .withValues(alpha: 0.4),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text('${score.points}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 3),
          const Text('pts',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Opt-out de recibir zumbidos (SPEC-264 fase 2) ───────────────────────────
class _ReceiveNudgesToggle extends ConsumerWidget {
  const _ReceiveNudgesToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(receiveNudgesProvider).valueOrNull ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Recibir zumbidos de mis rivales',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          Switch(
            value: value,
            activeThumbColor: _accent,
            onChanged: (v) =>
                ref.read(challengeControllerProvider).setReceiveNudges(v),
          ),
        ],
      ),
    );
  }
}

// ── Botón de acción ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent, width: filled ? 1 : 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18, color: filled ? AppColors.backgroundDark : _accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: filled ? AppColors.backgroundDark : _accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet: crear reto ───────────────────────────────────────────────────────
class _CreateChallengeSheet extends ConsumerStatefulWidget {
  const _CreateChallengeSheet();
  @override
  ConsumerState<_CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<_CreateChallengeSheet> {
  final _nameCtrl = TextEditingController();
  int _days = 30; // ≤ 30: la ventana de la racha en memoria cubre 30 días.
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final now = DateTime.now();
    final start = ChallengeScoring.dateKey(now);
    final end = ChallengeScoring.dateKey(now.add(Duration(days: _days - 1)));
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    try {
      final challenge =
          await ref.read(challengeControllerProvider).createChallenge(
                name: _nameCtrl.text,
                startDateKey: start,
                endDateKey: end,
              );
      if (!mounted) return;
      navigator.pop();
      router.push('/retos/${challenge.code}');
    } on ChallengeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Crear un reto',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Nombre del reto (ej. Reto de agosto)',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Duración',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [7, 14, 30].map((d) {
              final selected = _days == d;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _days = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? _accent.withValues(alpha: 0.18)
                            : AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected ? _accent : AppColors.border),
                      ),
                      child: Text('$d días',
                          style: TextStyle(
                              color:
                                  selected ? _accent : AppColors.textSecondary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFEF6C4D), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.backgroundDark),
                    )
                  : const Text('Crear e invitar',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet: unirse con código ────────────────────────────────────────────────
class _JoinChallengeSheet extends ConsumerStatefulWidget {
  const _JoinChallengeSheet();
  @override
  ConsumerState<_JoinChallengeSheet> createState() =>
      _JoinChallengeSheetState();
}

class _JoinChallengeSheetState extends ConsumerState<_JoinChallengeSheet> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    try {
      final challenge = await ref
          .read(challengeControllerProvider)
          .joinByCode(_codeCtrl.text);
      if (!mounted) return;
      navigator.pop();
      router.push('/retos/${challenge.code}');
    } on ChallengeException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unirme a un reto',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Escribe el código que te compartieron.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              UpperCaseTextFormatter(),
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                letterSpacing: 6,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ABC234',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, letterSpacing: 6),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFEF6C4D), fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.backgroundDark),
                    )
                  : const Text('Unirme',
                      style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatea el texto a MAYÚSCULAS mientras se escribe (código de invitación).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
