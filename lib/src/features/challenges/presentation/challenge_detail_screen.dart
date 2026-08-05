// SPEC-263: detalle de un reto — código de invitación + tablero de constancia.
//
// Al abrir, republica MI puntaje desde mi racha real (así el tablero refleja
// el estado del día sin depender de que la app estuviera abierta). El tablero
// lee los puntajes que cada miembro publicó; nadie ve los datos de salud de
// otro, solo su nombre y sus días cumplidos.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/challenges/application/challenge_controller.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

const Color _accent = AppColors.accent;
const Color _gold = Color(0xFFF59E0B);

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  const ChallengeDetailScreen({super.key, required this.code});
  final String code;

  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends ConsumerState<ChallengeDetailScreen> {
  bool _publishedOnce = false;

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeProvider(widget.code));
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(widget.code));
    final myId =
        ref.watch(currentUserStreamProvider).valueOrNull?.id ?? '';

    // Republica mi puntaje una sola vez, cuando llega la metadata del reto.
    ref.listen(challengeProvider(widget.code), (_, next) {
      final c = next.valueOrNull;
      if (c != null && !_publishedOnce) {
        _publishedOnce = true;
        ref.read(challengeControllerProvider).refreshMyScore(c);
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _header(challenge),
                const SizedBox(height: 16),
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
                  'Cada día que cumples tus pilares suma 1 punto. Gana quien '
                  'más días sume al final.',
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
                            name: scores[i].displayName,
                            points: scores[i].points,
                            isMe: scores[i].uid == myId,
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
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13)),
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
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
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
                  'lo que cuenta es cumplir tus pilares cada día.',
            ),
            _HowRow(
              icon: Icons.check_circle_rounded,
              title: 'Un día cumplido = 1 punto',
              body: 'Suma un punto cada día que califica para tu racha '
                  '(al menos 3 pilares, igual que en tu racha personal).',
            ),
            _HowRow(
              icon: Icons.emoji_events_rounded,
              title: 'Gana quien más días sume',
              body: 'Al terminar el período, el primero del tablero es quien '
                  'fue más constante. Sin trampas: sale de tu actividad real.',
            ),
            _HowRow(
              icon: Icons.group_add_rounded,
              title: 'Invita con el código',
              body: 'Comparte el código de invitación. Quien lo tenga puede '
                  'unirse y aparecer en el tablero.',
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

// ── Fila del tablero ─────────────────────────────────────────────────────────
class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.name,
    required this.points,
    required this.isMe,
  });
  final int rank;
  final String name;
  final int points;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => _gold,
      2 => const Color(0xFFCBD5E1),
      3 => const Color(0xFFB08D57),
      _ => AppColors.textSecondary,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _accent.withValues(alpha: 0.10) : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isMe ? _accent.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank',
                style: TextStyle(
                    color: medal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMe ? '$name (tú)' : name,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Text('$points',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          const Text('días',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
