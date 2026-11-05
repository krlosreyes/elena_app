import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/progress_v4_providers.dart';
import 'package:elena_app/src/features/analysis/application/weekly_window.dart';
import 'package:elena_app/src/features/analysis/domain/recomposition.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_insight.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_reading_sheet.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';

// Progreso v4 (2026-11-05) — el objetivo de Elena es la salud metabólica,
// que va de la mano con la recomposición corporal. La pantalla cuenta una
// historia en 3 niveles, en orden:
//
//   1. Tu cuerpo está cambiando — grasa vs. masa magra (no el peso solo).
//   2. Qué significa para tu salud — un beneficio por indicador que mejoró.
//   3. Cómo lo lograste — días cerrados por ti + pilares + UNA acción.
//
// + Tu glucosa (solo si el seguimiento está activo): la prueba por dentro.
// Sin dos mediciones comparables, el nivel 1 es una cuenta regresiva a los
// primeros resultados.
//
// Salen de esta pestaña: tendencia del puntaje, "Tu foco de hoy" (vive en
// Hoy) y las tarjetas grandes de accesos.

const _surface = Color(0xFF0C1422);
const _surface2 = Color(0xFF1A2332);
const _muted = Color(0xFF94A3B8);
const _faint = Color(0xFF64748B);
const _fatColor = Color(0xFFEF9F27);
const _glucoseColor = Color(0xFFE879F9);

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String _fecha(DateTime d) =>
    '${_dias[d.weekday - 1]} ${d.day} ${_meses[d.month - 1]}';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(recompositionProvider);
    final glucose = ref.watch(glucoseProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Progreso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (rec != null)
                  Text(
                    'Últimos ${rec.days} días',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (rec != null) ...[
              _BodyChangeCard(rec: rec),
              if (rec.benefits.isNotEmpty) ...[
                const SizedBox(height: 14),
                _BenefitsCard(benefits: rec.benefits),
              ],
            ] else
              const _FirstResultsCard(),
            const SizedBox(height: 14),
            _HabitsCard(
              muscleAtRisk: rec != null &&
                  (rec.verdict == RecompositionVerdict.fatLostMuscleLost ||
                      rec.verdict == RecompositionVerdict.noImprovement),
            ),
            if (glucose != null) ...[
              const SizedBox(height: 14),
              _GlucoseCard(data: glucose),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _Access(
                    label: 'Insignias',
                    onTap: () => context.push('/profile/badges')),
                const SizedBox(width: 8),
                _Access(label: 'Retos', onTap: () => context.push('/retos')),
                const SizedBox(width: 8),
                _Access(
                    label: 'Tu reloj',
                    onTap: () => context.push('/analysis/reloj')),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DashboardBottomNav(),
    );
  }
}

// ─── Piezas comunes ────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor, this.radius = 24});

  final Widget child;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text, {this.color = AppColors.metabolicGreen});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _Access extends StatelessWidget {
  const _Access({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
}

// ─── 1 · Tu cuerpo está cambiando ──────────────────────────────────

class _BodyChangeCard extends ConsumerWidget {
  const _BodyChangeCard({required this.rec});

  final Recomposition rec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(biometricLockProvider);
    final positive = rec.verdict != RecompositionVerdict.noImprovement;
    String good(double? v, String Function(double) f) =>
        v == null ? '—' : f(v);
    Color tone(double? v, {bool lowerIsBetter = true}) {
      if (v == null || v.abs() < 0.25) return Colors.white;
      final better = lowerIsBetter ? v < 0 : v > 0;
      return better ? AppColors.metabolicGreen : _fatColor;
    }

    return _Card(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('1 · TU CUERPO ESTÁ CAMBIANDO'),
          const SizedBox(height: 10),
          Text(
            rec.headline,
            style: TextStyle(
              color: positive ? Colors.white : const Color(0xFFE2E8F0),
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (rec.hasComposition) ...[
            const SizedBox(height: 16),
            _CompositionBar(label: 'Antes', point: rec.before),
            const SizedBox(height: 10),
            _CompositionBar(label: 'Hoy', point: rec.after),
            const SizedBox(height: 8),
            Row(
              children: [
                const _Legend(color: _fatColor, label: 'Grasa'),
                const SizedBox(width: 14),
                const _Legend(color: AppColors.metabolicGreen, label: 'Masa magra'),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'Grasa',
                value: good(rec.fatDeltaKg, Recomposition.signedKg),
                color: tone(rec.fatDeltaKg),
              ),
              const SizedBox(width: 8),
              _Stat(
                label: 'Masa magra',
                value: good(rec.leanDeltaKg, Recomposition.signedKg),
                color: tone(rec.leanDeltaKg, lowerIsBetter: false),
              ),
              const SizedBox(width: 8),
              _Stat(
                label: 'Cintura',
                value: good(rec.waistDeltaCm, Recomposition.signedCm),
                color: tone(rec.waistDeltaCm),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${rec.weightNote}'
            '${lock.isLocked && lock.unlocksAt != null ? ' Próxima medición: ${_fecha(lock.unlocksAt!)}.' : ''}',
            style: const TextStyle(color: _faint, fontSize: 12.5, height: 1.4),
          ),
          if (!lock.isLocked) ...[
            const SizedBox(height: 10),
            const _MeasureButton(),
          ],
        ],
      ),
    );
  }
}

class _MeasureButton extends StatelessWidget {
  const _MeasureButton();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: () => showBiometricCheckInSheet(context),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: AppColors.metabolicGreen.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.straighten_rounded,
              size: 18, color: AppColors.metabolicGreen),
          label: const Text(
            'Registrar mis medidas de esta semana',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      );
}

class _CompositionBar extends StatelessWidget {
  const _CompositionBar({required this.label, required this.point});

  final String label;
  final BodyPoint point;

  @override
  Widget build(BuildContext context) {
    final fat = point.fatKg ?? 0;
    final lean = point.leanKg ?? point.weightKg;
    final total = fat + lean;
    final int fatFlex =
        total <= 0 ? 1 : math.max(1, math.min(999, (fat / total * 1000).round()));
    String kg(double v) => v.toStringAsFixed(1).replaceAll('.', ',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: _muted, fontSize: 12.5)),
            ),
            Text(
              'grasa ${kg(fat)} kg · magra ${kg(lean)} kg',
              style: const TextStyle(color: _faint, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                Expanded(flex: fatFlex, child: Container(color: _fatColor)),
                const SizedBox(width: 2),
                Expanded(
                  flex: 1000 - fatFlex,
                  child: Container(color: AppColors.metabolicGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 11.5)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Sin dos mediciones comparables: cuenta regresiva a los primeros
/// resultados (lo que más pesa en el abandono del día 5–6).
class _FirstResultsCard extends ConsumerWidget {
  const _FirstResultsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(biometricLockProvider);
    final now = DateTime.now();
    final unlocks = lock.unlocksAt;
    final daysLeft = (lock.isLocked && unlocks != null)
        ? math.max(
            1,
            DateTime(unlocks.year, unlocks.month, unlocks.day)
                .difference(DateTime(now.year, now.month, now.day))
                .inDays)
        : 0;

    return _Card(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('TUS PRIMEROS RESULTADOS'),
          const SizedBox(height: 10),
          if (daysLeft > 0) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$daysLeft',
                  style: const TextStyle(
                    color: AppColors.metabolicGreen,
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    daysLeft == 1
                        ? 'día para tus primeros resultados'
                        : 'días para tus primeros resultados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'El ${_fecha(unlocks!)} vuelves a medirte y te mostramos cuánta '
              'grasa perdiste y cuánto músculo conservaste.',
              style: const TextStyle(
                  color: Color(0xFFCBD5E1), fontSize: 14.5, height: 1.45),
            ),
          ] else ...[
            const Text(
              'Registra tus medidas para empezar a ver tu recomposición.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Con dos mediciones separadas por una semana te mostramos '
              'cuánta grasa perdiste y cuánto músculo conservaste.',
              style:
                  TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.45),
            ),
            const SizedBox(height: 12),
            const _MeasureButton(),
          ],
        ],
      ),
    );
  }
}

// ─── 2 · Qué significa para tu salud ───────────────────────────────

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.benefits});

  final List<HealthBenefit> benefits;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('2 · QUÉ SIGNIFICA PARA TU SALUD'),
          for (final b in benefits) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.metabolicGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    b == HealthBenefit.lessAbdominalFat
                        ? Icons.straighten_rounded
                        : Icons.bolt_rounded,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefitCopy(b).$1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        benefitCopy(b).$2,
                        style: const TextStyle(
                            color: _muted, fontSize: 13, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 3 · Cómo lo lograste ──────────────────────────────────────────

class _HabitsCard extends ConsumerWidget {
  const _HabitsCard({required this.muscleAtRisk});

  final bool muscleAtRisk;

  static const _labels = {
    ProgressPillar.ayuno: 'Ayuno',
    ProgressPillar.sueno: 'Sueño',
    ProgressPillar.agua: 'Agua',
    ProgressPillar.movimiento: 'Movimiento',
    ProgressPillar.comida: 'Comida',
  };
  static const _colors = {
    ProgressPillar.ayuno: Color(0xFF00C49A),
    ProgressPillar.sueno: Color(0xFF818CF8),
    ProgressPillar.agua: Color(0xFF38BDF8),
    ProgressPillar.movimiento: Color(0xFF2DD4BF),
    ProgressPillar.comida: Color(0xFFFB923C),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = ref.watch(closedByYou30Provider);
    final weekly = ref.watch(weeklyPillarDaysProvider).valueOrNull;
    final days = weekly == null
        ? null
        : {
            ProgressPillar.ayuno: weekly.fasting,
            ProgressPillar.sueno: weekly.sleep,
            ProgressPillar.agua: weekly.hydration,
            ProgressPillar.movimiento: weekly.exercise,
            ProgressPillar.comida: weekly.nutrition,
          };
    final weakest = days == null ? null : weakestPillar(days);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Kicker('3 · CÓMO LO LOGRASTE')),
              if (closed != null && closed.$2 > 0)
                Text(
                  '${closed.$1} de ${closed.$2} días cerrados por ti',
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Esta semana',
            style: TextStyle(color: _faint, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (days == null)
            const SizedBox(
              height: 40,
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            for (final p in ProgressPillar.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        _labels[p]!,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (days[p]! / 7).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.07),
                          valueColor: AlwaysStoppedAnimation(
                              p == weakest ? _fatColor : _colors[p]!),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${days[p]}/7',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: p == weakest ? _fatColor : _muted,
                          fontSize: 12.5,
                          fontWeight:
                              p == weakest ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (weakest != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fatColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                pillarTip(weakest, muscleAtRisk: muscleAtRisk),
                style: const TextStyle(
                    color: Color(0xFFFAC775), fontSize: 13, height: 1.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tu glucosa ────────────────────────────────────────────────────

class _GlucoseCard extends StatelessWidget {
  const _GlucoseCard({required this.data});

  final GlucoseProgress data;

  @override
  Widget build(BuildContext context) {
    final avg = data.avg14;
    final delta = data.delta;
    final insight = data.insight;
    final preliminary =
        insight?.confidence == GlucoseInsightConfidence.preliminar;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/analysis/glucosa'),
      child: _Card(
        borderColor: _glucoseColor.withValues(alpha: 0.28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Kicker('TU GLUCOSA · LA PRUEBA POR DENTRO',
                color: _glucoseColor),
            const SizedBox(height: 12),
            if (avg == null)
              const Text(
                'Aún no tienes lecturas en ayunas en los últimos 14 días.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('En ayunas · promedio 14 días',
                            style: TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            text: avg.round().toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                            children: const [
                              TextSpan(
                                text: ' mg/dL',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (delta != null)
                          Text(
                            delta.round() == 0
                                ? 'igual que las 2 semanas anteriores'
                                : '${delta < 0 ? '−' : '+'}${delta.abs().round()} vs. 2 semanas antes',
                            style: TextStyle(
                              color: delta < 0
                                  ? AppColors.metabolicGreen
                                  : (delta.round() == 0 ? _muted : _fatColor),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (data.recent.length >= 3)
                    SizedBox(
                      width: 110,
                      height: 44,
                      child: CustomPaint(
                          painter: _SparkPainter(data.recent)),
                    ),
                ],
              ),
            if (insight != null) ...[
              const SizedBox(height: 10),
              Text(
                '${insight.observation}${preliminary ? ' (preliminar)' : ''}',
                style: const TextStyle(
                    color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
              ),
            ] else if (avg != null && delta != null && delta < 0) ...[
              const SizedBox(height: 10),
              const Text(
                'Tu cuerpo está controlando mejor el azúcar: confirma que tus '
                'cambios están funcionando.',
                style: TextStyle(
                    color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => showGlucoseReadingSheet(context),
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: _glucoseColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Registrar glucosa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min).toDouble();
    final hi = values.reduce(math.max).toDouble();
    final span = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    final dx = (size.width - 6) / (values.length - 1);
    Offset at(int i) => Offset(
          3 + i * dx,
          4 + (1 - (values[i] - lo) / span) * (size.height - 8),
        );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = _glucoseColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(at(values.length - 1), 3.5, Paint()..color = _glucoseColor);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}
