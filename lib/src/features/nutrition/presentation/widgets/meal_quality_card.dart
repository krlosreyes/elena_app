// Registro de comidas con una sola barra (2026-11-07).
//
// Reemplaza en Hoy a "Cómo comer ahora" y a "Lo que sigue". El usuario
// desliza de Chatarra a Saludable según su percepción y registra. La
// tarjeta muestra cuántas comidas pide su protocolo, las que lleva (con su
// calidad) y el puntaje del pilar Comida, que sale de MealQuality.dayScore.
//
// Solo se muestra fuera del ayuno: en ayuno no se registran comidas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_quality.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

const _junk = Color(0xFFEF4444);
const _ok = Color(0xFFF59E0B);
const _healthy = Color(0xFF10B981);

/// Color de la barra para una calidad (rojo → ámbar → verde).
Color mealQualityColor(double q) {
  if (q <= 0.5) return Color.lerp(_junk, _ok, q / 0.5)!;
  return Color.lerp(_ok, _healthy, (q - 0.5) / 0.5)!;
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// "Comida 2 de 2" / "Comida extra".
String mealOrdinalLabel(int registered, int target) {
  final next = registered + 1;
  if (next > target) return 'Comida extra';
  return 'Comida $next de $target';
}

class MealQualityCard extends ConsumerStatefulWidget {
  const MealQualityCard({super.key});

  @override
  ConsumerState<MealQualityCard> createState() => _MealQualityCardState();
}

class _MealQualityCardState extends ConsumerState<MealQualityCard> {
  double _q = MealQuality.initial;
  DateTime? _time; // null = ahora
  bool _saving = false;

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time ?? now),
      helpText: '¿A qué hora comiste?',
    );
    if (picked == null || !mounted) return;
    var t = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    // Una hora "futura" es de ayer (registraste tarde, pasada la medianoche).
    if (t.isAfter(now)) t = t.subtract(const Duration(days: 1));
    setState(() => _time = t);
  }

  Future<void> _register({bool force = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(nutritionProvider.notifier).logMeal(
            quality: double.parse(_q.toStringAsFixed(2)),
            mealTime: _time,
            forceLog: force,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _q = MealQuality.initial;
        _time = null;
      });
    } on MealTooSoonException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Tu última comida fue a las ${_hhmm(e.lastMealAt)}. Deja al menos '
          '2 horas entre comidas: puedes registrar desde las '
          '${_hhmm(e.canRegisterAt)}.',
        ),
      ));
    } on MealIntervalWarning catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Comiste hace poco'),
          content: Text(
            'Tu última comida fue a las ${_hhmm(e.lastMealAt)}. Lo ideal es '
            'esperar 3 horas para que tu insulina baje. ¿La registras igual?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar'),
            ),
          ],
        ),
      );
      if (ok == true) return _register(force: true);
      return;
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('No pudimos guardar la comida. Inténtalo de nuevo.'),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(NutritionLog log) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar esta comida?'),
        content: Text(
          '${_hhmm(log.timestamp)} · ${MealQuality.labelOf(log.quality ?? 0.5)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(nutritionProvider.notifier).deleteMealById(log.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionProvider);
    final target = state.targetMeals.clamp(1, 6);
    final logs = [...state.todayLogs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final pct = (state.nutritionScore * 100).round();
    final color = mealQualityColor(_q);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1422),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded,
                  size: 18, color: Color(0xFFFB923C)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '¿Qué tan saludable fue tu comida?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (logs.isNotEmpty)
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: mealQualityColor(state.nutritionScore),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tu protocolo pide $target '
            '${target == 1 ? 'comida' : 'comidas'} en tu ventana · '
            'llevas ${logs.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < logs.length; i++)
                  _MealChip(
                    log: logs[i],
                    extra: i >= target,
                    onLongPress: () => _confirmDelete(logs[i]),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                mealOrdinalLabel(logs.length, target),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        _time == null ? 'Ahora' : _hhmm(_time!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              MealQuality.labelOf(_q),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
            ),
            child: Semantics(
              label: 'Calidad de la comida',
              value: MealQuality.labelOf(_q),
              child: Slider(
                value: _q,
                onChanged: _saving
                    ? null
                    : (v) {
                        if (MealQuality.zoneOf(v) != MealQuality.zoneOf(_q)) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() => _q = v);
                      },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (label, c) in [
                  ('Chatarra', _junk),
                  ('Aceptable', _ok),
                  ('Saludable', _healthy),
                ])
                  Text(
                    label,
                    style: TextStyle(
                      color: c.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            MealQuality.hintOf(_q),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                foregroundColor: const Color(0xFF032A22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _saving ? 'Guardando…' : 'Registrar comida',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Mantén presionada una comida para borrarla',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({
    required this.log,
    required this.extra,
    required this.onLongPress,
  });

  final NutritionLog log;
  final bool extra;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final q = log.quality;
    final c = q == null ? Colors.white54 : mealQualityColor(q);
    final label = q == null ? 'Registrada' : MealQuality.labelOf(q);
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${_hhmm(log.timestamp)} · $label${extra ? ' · extra' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
