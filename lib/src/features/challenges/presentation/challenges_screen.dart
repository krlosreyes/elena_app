// SPEC-263: "Retos" — competencia social sana por CONSTANCIA.
//
// Lista los retos donde participo. Desde aquí creo un reto (genero un código
// para invitar) o me uno con el código de alguien más. El puntaje es días que
// califican para la racha en el período — se premia el hábito, no la báscula.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/challenges/application/challenge_controller.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';

const Color _accent = AppColors.accent;

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
                _intro(),
                const SizedBox(height: 12),
                const _ReceiveNudgesToggle(),
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
                const SizedBox(height: 24),
                if (sorted.isEmpty)
                  _emptyState()
                else
                  ...sorted.map((c) => _ChallengeRow(challenge: c)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: _accent, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reta a tus amigos a ser constantes. Gana quien más días '
                'cumpla sus pilares en el período — no se trata de peso, '
                'sino de sostener el hábito.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.35),
              ),
            ),
          ],
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Icon(Icons.groups_2_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 56),
            const SizedBox(height: 12),
            const Text(
              'Todavía no estás en ningún reto',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea uno e invita con el código, o únete al de alguien más.',
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

  // ── Crear ───────────────────────────────────────────────────────────────
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

  // ── Unirse ────────────────────────────────────────────────────────────────
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

// ── Opt-out de recibir zumbidos (SPEC-264 fase 2) ───────────────────────────
class _ReceiveNudgesToggle extends ConsumerWidget {
  const _ReceiveNudgesToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(receiveNudgesProvider).valueOrNull ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
            activeColor: _accent,
            onChanged: (v) =>
                ref.read(challengeControllerProvider).setReceiveNudges(v),
          ),
        ],
      ),
    );
  }
}

// ── Fila de un reto ─────────────────────────────────────────────────────────
class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({required this.challenge});
  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final todayKey = ChallengeScoring.dateKey(DateTime.now());
    final status = challenge.statusOn(todayKey);
    final (label, color) = switch (status) {
      ChallengeStatus.upcoming => ('Próximo', AppColors.textSecondary),
      ChallengeStatus.active => ('En curso', _accent),
      ChallengeStatus.ended => ('Terminado', AppColors.textSecondary),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/retos/${challenge.code}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${challenge.memberCount} participantes · '
                      '${challenge.startDateKey} → ${challenge.endDateKey}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
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
          border: Border.all(color: _accent),
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
    // Capturados antes del await: tras pop, el context de la hoja ya no sirve.
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
