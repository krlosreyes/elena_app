// SPEC-263 / SPEC-264: detalle de un reto.
//
// Al abrir, republica MI puntaje desde mi racha real. El tablero muestra, por
// competidor, sus 5 anillos del día (estilo Apple Fitness) y sus puntos — se
// comparte el LOGRO (cerró el anillo o no), nunca el dato crudo. Puedo enviar
// interacciones POSITIVAS (zumbidos) a mis rivales, que llegan in-app. Al
// cerrar el reto, aparece el ganador y la opción de revancha.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/challenges/application/challenge_controller.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_rings.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/features/challenges/domain/nudge.dart';
import 'package:elena_app/src/features/challenges/presentation/nudge_buzz.dart';
import 'package:elena_app/src/features/challenges/presentation/widgets/challenge_avatar.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const Color _accent = AppColors.accent;
const Color _gold = Color(0xFFF59E0B);

List<({IconData icon, bool closed})> _ringList(ChallengeRings r) => [
      (icon: Icons.timer_rounded, closed: r.ayuno),
      (icon: Icons.fitness_center_rounded, closed: r.ejercicio),
      (icon: Icons.restaurant_rounded, closed: r.nutricion),
      (icon: Icons.bedtime_rounded, closed: r.sueno),
      (icon: Icons.water_drop_rounded, closed: r.hidratacion),
    ];

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _publishedOnce = false;
  bool _outcomeRecorded = false;
  bool _nudgeBaselineSet = false;
  final Set<String> _seenNudgeIds = {};

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeProvider(widget.code));
    final leaderboardAsync =
        ref.watch(challengeLeaderboardProvider(widget.code));
    final myId = ref.watch(currentUserStreamProvider).valueOrNull?.id ?? '';

    // Republica mi puntaje una sola vez, cuando llega la metadata del reto.
    ref.listen(challengeProvider(widget.code), (_, next) {
      final c = next.valueOrNull;
      if (c != null && !_publishedOnce) {
        _publishedOnce = true;
        ref.read(challengeControllerProvider).refreshMyScore(c);
      }
    });

    // Recepción in-app de zumbidos: la primera tanda es baseline (no se muestra,
    // para no spamear el histórico al abrir); las nuevas sí aparecen.
    ref.listen(incomingNudgesProvider(widget.code), (_, next) {
      final list = next.valueOrNull;
      if (list == null) return;
      if (!_nudgeBaselineSet) {
        _nudgeBaselineSet = true;
        _seenNudgeIds.addAll(list.map((n) => n.id));
        return;
      }
      for (final n in list) {
        if (_seenNudgeIds.contains(n.id)) continue;
        _seenNudgeIds.add(n.id);
        final kind = n.kind;
        if (kind != null && mounted) {
          // Buzz in-app: vibración + overlay que tiembla (estilo MSN).
          showNudgeBuzz(context, kind: kind, fromName: n.fromName);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Reto',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Cómo funciona',
            onPressed: () => _showHowItWorks(context),
          ),
          challengeAsync.maybeWhen(
            data: (c) => (c != null && c.ownerId == myId)
                ? IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => _confirmDelete(context),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _accent)),
          error: (_, __) => _notFound(),
          data: (challenge) {
            if (challenge == null) return _notFound();
            final todayKey = ChallengeScoring.dateKey(DateTime.now());
            final ended = challenge.statusOn(todayKey) == ChallengeStatus.ended;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _header(challenge),
                const SizedBox(height: 16),
                if (ended)
                  leaderboardAsync.maybeWhen(
                    data: (scores) =>
                        _endedBanner(context, challenge, scores, myId),
                    orElse: () => const SizedBox.shrink(),
                  )
                else
                  _inviteCard(context, challenge),
                const SizedBox(height: 24),
                const Text('TABLERO',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text(
                  'Cada anillo (pilar) que cierras suma 1 punto. Gana quien más '
                  'sume al final. Anima a tus rivales con una interacción.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.35),
                ),
                const SizedBox(height: 12),
                leaderboardAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(color: _accent)),
                  ),
                  error: (_, __) => const Text(
                    'No pudimos cargar el tablero.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  data: (scores) {
                    if (scores.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Aún no hay puntajes. En cuanto cada quien abra el '
                          'reto, aparecerá aquí.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < scores.length; i++)
                          _LeaderRow(
                            rank: i + 1,
                            score: scores[i],
                            isMe: scores[i].uid == myId,
                            onNudge: scores[i].uid == myId
                                ? null
                                : () => _openNudgeSheet(
                                    context, challenge.code, scores[i]),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(Challenge c) {
    final todayKey = ChallengeScoring.dateKey(DateTime.now());
    final status = c.statusOn(todayKey);
    final statusLabel = switch (status) {
      ChallengeStatus.upcoming => 'Empieza el ${c.startDateKey}',
      ChallengeStatus.active => 'En curso · termina el ${c.endDateKey}',
      ChallengeStatus.ended => 'Terminado el ${c.endDateKey}',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(c.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('$statusLabel · ${c.memberCount} participantes',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _inviteCard(BuildContext context, Challenge c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CÓDIGO DE INVITACIÓN',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(c.code,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: _accent),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: c.code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Cierre del reto: ganador + revancha ────────────────────────────────
  Widget _endedBanner(
    BuildContext context,
    Challenge challenge,
    List<ChallengeScore> scores,
    String myId,
  ) {
    final winner = ChallengeScoring.winner(scores);
    // Contabiliza el resultado una sola vez (idempotente por código en el
    // wallet aunque se reabra en otra sesión).
    if (!_outcomeRecorded && winner != null && myId.isNotEmpty) {
      _outcomeRecorded = true;
      final iWon = winner.uid == myId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(challengeControllerProvider)
            .recordOutcome(code: challenge.code, didWin: iWon);
      });
    }
    final iWon = winner != null && winner.uid == myId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: _gold, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  winner == null
                      ? 'Reto terminado'
                      : iWon
                          ? '¡Ganaste el reto! 🎉'
                          : 'Ganó ${winner.displayName}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'No dejes que se enfríe el hábito: una revancha mantiene la racha '
            'viva. Encadenar retos es lo que de verdad instala la constancia.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: AppColors.backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Otra vuelta (revancha)',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              onPressed: () => _startRematch(context, challenge),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startRematch(BuildContext context, Challenge old) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final fresh = await ref.read(challengeControllerProvider).rematch(old);
      router.pushReplacement('/retos/${fresh.code}');
    } on ChallengeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  // ── Enviar interacción ─────────────────────────────────────────────────
  void _openNudgeSheet(
      BuildContext context, String code, ChallengeScore target) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NudgeSheet(code: code, target: target),
    );
  }

  Widget _notFound() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este reto ya no existe o no tienes acceso.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );

  void _showHowItWorks(BuildContext context) {
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
            Text('Cómo funciona el reto',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            _HowRow(
              icon: Icons.favorite_rounded,
              title: 'Se mide constancia, no peso',
              body: 'Compites por sostener el hábito. La báscula no entra: '
                  'lo que cuenta es cerrar tus pilares cada día.',
            ),
            _HowRow(
              icon: Icons.blur_circular_rounded,
              title: 'Cada anillo cerrado = 1 punto',
              body: 'Tus 5 pilares son 5 anillos. Cada uno que cierras suma un '
                  'punto (máx 5 al día). Todos ven tus anillos, nunca tus datos.',
            ),
            _HowRow(
              icon: Icons.emoji_events_rounded,
              title: 'Gana quien más sume',
              body: 'Al terminar el período, el primero del tablero fue el más '
                  'constante. Sale de tu actividad real: sin trampas.',
            ),
            _HowRow(
              icon: Icons.waving_hand_rounded,
              title: 'Anima a tus rivales',
              body: 'Envía porras o un zumbido (cuestan perlas) para que nadie '
                  'se quede atrás. Solo buena onda.',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('¿Borrar el reto?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Se cerrará para todos los participantes. Esta acción no se '
          'puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar',
                style: TextStyle(color: Color(0xFFEF6C4D))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(challengeControllerProvider).deleteChallenge(widget.code);
      if (mounted) context.pop();
    } on ChallengeException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

// ── Anillos (5 pilares del día) ─────────────────────────────────────────────
class _RingsStrip extends StatelessWidget {
  const _RingsStrip({required this.rings});
  final ChallengeRings rings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in _ringList(rings))
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: r.closed
                    ? _accent.withValues(alpha: 0.9)
                    : Colors.transparent,
                border: Border.all(
                  color: r.closed
                      ? _accent
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                r.icon,
                size: 13,
                color: r.closed
                    ? AppColors.backgroundDark
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Fila del tablero ─────────────────────────────────────────────────────────
class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.score,
    required this.isMe,
    required this.onNudge,
  });
  final int rank;
  final ChallengeScore score;
  final bool isMe;
  final VoidCallback? onNudge;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => _gold,
      2 => const Color(0xFFCBD5E1),
      3 => const Color(0xFFB08D57),
      _ => AppColors.textSecondary,
    };
    final behind = !score.qualifiedToday; // va colgado hoy
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _accent.withValues(alpha: 0.10) : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMe ? _accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                child: Text('$rank',
                    style: TextStyle(
                        color: medal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              // SPEC-299: avatar (foto de perfil o inicial) para personalizar.
              ChallengeAvatar(
                name: score.displayName,
                photoUrl: score.photoUrl,
                size: 36,
                highlight: isMe,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isMe ? '${score.displayName} (tú)' : score.displayName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Text('${score.points}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              const Text('pts',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (onNudge != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onNudge,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: behind
                          ? _gold.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Icon(Icons.waving_hand_rounded,
                        size: 16, color: behind ? _gold : _accent),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RingsStrip(rings: score.todayRings),
              const Spacer(),
              if (behind && onNudge != null)
                const Text('va colgado hoy',
                    style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sheet: enviar una interacción ────────────────────────────────────────────
class _NudgeSheet extends ConsumerWidget {
  const _NudgeSheet({required this.code, required this.target});
  final String code;
  final ChallengeScore target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Animar a ${target.displayName}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Le llega como un mensaje tuyo. Solo buena onda.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ...NudgeCatalog.all.map(
            (kind) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _send(context, ref, kind),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(kind.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(kind.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.blur_circular_rounded,
                          size: 16,
                          color:
                              const Color(0xFFD8B4E2).withValues(alpha: 0.9)),
                      const SizedBox(width: 4),
                      Text('${kind.cost}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(
      BuildContext context, WidgetRef ref, NudgeKind kind) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(challengeControllerProvider).sendNudge(
            code: code,
            toUid: target.uid,
            kind: kind,
          );
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
            content: Text('${kind.emoji} enviado a ${target.displayName}')),
      );
    } on ChallengeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

// ── Fila del explainer "cómo funciona" ──────────────────────────────────────
class _HowRow extends StatelessWidget {
  const _HowRow({required this.icon, required this.title, required this.body});
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
          Icon(icon, color: _accent, size: 22),
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
