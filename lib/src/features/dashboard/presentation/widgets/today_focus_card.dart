// Rediseño Hoy (2026-10-30): "Tu foco de hoy" — UNA recomendación concreta.
//
// Sale del mismo motor que el foco del boletín en Progreso
// (weeklyCoachingProvider → weakest.suggestedAction), así que el texto es
// idéntico en las dos pantallas. "Hecho" lo marca como cumplido por hoy
// (se guarda en SharedPreferences con la fecha; mañana vuelve a aparecer).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/features/analysis/application/weekly_coaching_provider.dart';

/// Texto del foco del día, o null si no hay recomendación (sin datos).
/// Público para que Progreso muestre exactamente lo mismo.
final todayFocusTextProvider = Provider.autoDispose<String?>((ref) {
  final insight = ref.watch(weeklyCoachingProvider).valueOrNull;
  if (insight == null || insight.isEmpty) return null;
  final weak = insight.weakest;
  if (weak != null) return weak.suggestedAction;
  if (insight.isFullySustained) {
    return 'Sostienes tus 5 pilares. Repite lo de ayer.';
  }
  return null;
});

class TodayFocusCard extends ConsumerStatefulWidget {
  const TodayFocusCard({super.key, this.title = 'Tu foco de hoy'});

  /// Rediseño Hoy (2026-11-04): en Hoy se titula "Lo que sigue".
  final String title;

  @override
  ConsumerState<TodayFocusCard> createState() => _TodayFocusCardState();
}

class _TodayFocusCardState extends ConsumerState<TodayFocusCard> {
  static const _kDoneKey = 'todayFocus.doneDate';
  bool _done = false;

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() => _done = prefs.getString(_kDoneKey) == _todayKey());
    }).catchError((_) {});
  }

  Future<void> _markDone() async {
    setState(() => _done = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDoneKey, _todayKey());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final text = ref.watch(todayFocusTextProvider);
    if (text == null) return const SizedBox.shrink();
    const amber = Color(0xFFF59E0B);
    const green = Color(0xFF22D3A8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_done ? green : amber).withValues(alpha: 0.15),
            ),
            child: Icon(
              _done ? Icons.check_rounded : Icons.flag_rounded,
              color: _done ? green : amber,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _done ? green : amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _done ? 0.55 : 0.92),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    decoration: _done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!_done)
            TextButton(
              onPressed: _markDone,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hecho',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
