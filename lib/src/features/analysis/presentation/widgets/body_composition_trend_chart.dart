// SPEC-152 / SPEC-157 — Widget de tendencia de composición corporal.
//
// Ahora conectado al SegmentedRangeControl global (analysisRangeProvider).
// El período interno 30/60/90 se eliminó — el filtro Semana/Mes/3M/6M/1A
// de la pantalla de detalle controla el rango.
//
// Orden de tabs (pedido por producto):
//   Peso Total → % Grasa → % Masa Magra → Cintura cm → WHTR
//
// Cada tab muestra:
//   1. Gráfico de línea
//   2. Barra de estado (zona de salud)
//   3. Card de feedback contextual

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/biometric_trend_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/analysis/domain/body_composition_metric.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/body_silhouette.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── Orden de tabs ────────────────────────────────────────────────────────

const _kTabOrder = [
  BodyCompositionMetric.weight,
  BodyCompositionMetric.bodyFatPct,
  BodyCompositionMetric.leanMassKg,
  BodyCompositionMetric.waistCm,
  BodyCompositionMetric.whtr,
];

// Labels personalizados que muestran unidad explícita
String _tabLabel(BodyCompositionMetric m) {
  switch (m) {
    case BodyCompositionMetric.weight:
      return 'Peso Total';
    case BodyCompositionMetric.bodyFatPct:
      return '% Grasa';
    case BodyCompositionMetric.leanMassKg:
      return '% Masa Magra';
    case BodyCompositionMetric.waistCm:
      return 'Cintura cm';
    case BodyCompositionMetric.whtr:
      return 'WHTR';
  }
}

// ─── Mapeo AnalysisRange → días ──────────────────────────────────────────

int _daysFor(AnalysisRange r) {
  switch (r) {
    case AnalysisRange.w1:
      return 7;
    case AnalysisRange.m1:
      return 30;
    case AnalysisRange.m3:
      return 90;
    case AnalysisRange.m6:
      return 180;
    case AnalysisRange.y1:
      return 365;
  }
}

// ─── Widget principal ─────────────────────────────────────────────────────

class BodyCompositionTrendChart extends ConsumerStatefulWidget {
  const BodyCompositionTrendChart({super.key});

  @override
  ConsumerState<BodyCompositionTrendChart> createState() =>
      _BodyCompositionTrendChartState();
}

class _BodyCompositionTrendChartState
    extends ConsumerState<BodyCompositionTrendChart> {
  BodyCompositionMetric _metric = BodyCompositionMetric.weight;

  @override
  Widget build(BuildContext context) {
    final range = ref.watch(analysisRangeProvider);
    final days = _daysFor(range);
    final asyncCheckIns = ref.watch(biometricTrendProvider(days));
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final heightCm = (user?.height ?? 0) > 0 ? user!.height : null;
    final bodyFatPct = user?.bodyFatPercentage;
    final isMale = (user?.gender ?? 'M').toUpperCase() == 'M';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildMetricTabs(),
          const SizedBox(height: 18),
          asyncCheckIns.when(
            loading: () => _buildLoading(),
            error: (_, __) => _buildErrorBox(),
            data: (list) => _buildContent(
              list,
              heightCm: heightCm,
              isMale: isMale,
              days: days,
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: BodySilhouette(bodyFatPct: bodyFatPct, isMale: isMale),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Text(
      'COMPOSICIÓN CORPORAL',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 10,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // ─── Tabs ────────────────────────────────────────────────────────────

  Widget _buildMetricTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _kTabOrder.map((m) {
          final isSelected = m == _metric;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _metric = m),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? m.accentColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? m.accentColor.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  _tabLabel(m),
                  style: TextStyle(
                    color: isSelected ? m.accentColor : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Estados ────────────────────────────────────────────────────────

  Widget _buildLoading() => Container(
        height: 160,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.metabolicGreen),
        ),
      );

  Widget _buildErrorBox() => Container(
        height: 160,
        alignment: Alignment.center,
        child: Text(
          'No pudimos cargar la tendencia.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
        ),
      );

  // ─── Contenido principal ─────────────────────────────────────────────

  Widget _buildContent(
    List<BiometricCheckIn> all, {
    double? heightCm,
    required bool isMale,
    required int days,
  }) {
    final samples = <_TrendPoint>[];
    for (final ci in all) {
      final v = _metric.selectValue(ci, heightCm: heightCm);
      if (v != null) samples.add(_TrendPoint(value: v, dateKey: ci.date));
    }

    if (samples.length < 2) {
      return _buildEmptyState(samples.isEmpty);
    }

    final first = samples.first;
    final last = samples.last;
    final delta = last.value - first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Valor + delta
        _buildValueHeadline(last.value, delta, days),
        const SizedBox(height: 14),
        // 2. Gráfico de línea
        _buildChart(samples),
        const SizedBox(height: 6),
        _buildAxisLabels(days),
        const SizedBox(height: 16),
        // 3. Barra de estado
        _buildStatusBar(last.value, isMale: isMale),
        const SizedBox(height: 14),
        // 4. Feedback card
        _buildFeedbackCard(last.value, delta, isMale: isMale),
      ],
    );
  }

  Widget _buildEmptyState(bool noSamples) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        noSamples
            ? _metric.emptyStateMessage
            : 'Necesitamos al menos 2 mediciones — regístrate otra vez.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  // ─── Valor + delta ───────────────────────────────────────────────────

  Widget _buildValueHeadline(double currentValue, double delta, int days) {
    // Para esta métrica ¿bajar es mejor (peso, grasa, cintura, whtr)?
    final lowerIsBetter = _metric != BodyCompositionMetric.leanMassKg;
    final Color deltaColor;
    final IconData deltaIcon;
    if (delta.abs() < 0.01) {
      deltaColor = Colors.white.withValues(alpha: 0.45);
      deltaIcon = Icons.remove_rounded;
    } else if ((delta < 0) == lowerIsBetter) {
      // Cambio favorable
      deltaColor = AppColors.metabolicGreen;
      deltaIcon = delta < 0
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
    } else {
      // Cambio desfavorable
      deltaColor = const Color(0xFFF59E0B);
      deltaIcon = delta < 0
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _metric.formatValue(currentValue),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _metric.unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(deltaIcon, color: deltaColor, size: 14),
            const SizedBox(width: 4),
            Text(
              '${_metric.deltaCopyFor(delta)} en $days días',
              style: TextStyle(
                color: deltaColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Gráfico ─────────────────────────────────────────────────────────

  Widget _buildChart(List<_TrendPoint> samples) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(
          values: samples.map((s) => s.value).toList(),
          accentColor: _metric.accentColor,
        ),
      ),
    );
  }

  Widget _buildAxisLabels(int days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$days días atrás',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10,
                letterSpacing: 0.3)),
        Text('hoy',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 10,
                letterSpacing: 0.3)),
      ],
    );
  }

  // ─── Barra de estado (zona de salud) ─────────────────────────────────

  Widget _buildStatusBar(double value, {required bool isMale}) {
    final zone = _healthZone(value, isMale: isMale);
    final fill = _healthFill(value, isMale: isMale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ESTADO',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: zone.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: zone.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                zone.label,
                style: TextStyle(
                  color: zone.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(zone.color),
          ),
        ),
      ],
    );
  }

  // ─── Feedback card ───────────────────────────────────────────────────

  Widget _buildFeedbackCard(
    double current,
    double delta, {
    required bool isMale,
  }) {
    final text = _feedbackText(current, delta, isMale: isMale);
    if (text == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _metric.feedbackEmoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lógica de zona de salud ─────────────────────────────────────────

  _HealthZone _healthZone(double value, {required bool isMale}) {
    switch (_metric) {
      case BodyCompositionMetric.weight:
        // Sin meta de peso en el modelo actual — mostramos tendencia
        return const _HealthZone('Seguimiento', Color(0xFF60A5FA));

      case BodyCompositionMetric.bodyFatPct:
        // ACSM ranges (adultos)
        if (isMale) {
          if (value < 6) return const _HealthZone('Muy bajo', Color(0xFF38BDF8));
          if (value <= 17) return const _HealthZone('Atlético ✓', Color(0xFF10B981));
          if (value <= 24) return const _HealthZone('Saludable ✓', Color(0xFF10B981));
          if (value <= 31) return const _HealthZone('Por mejorar', Color(0xFFF59E0B));
          return const _HealthZone('Riesgo', Color(0xFFEF4444));
        } else {
          if (value < 14) return const _HealthZone('Muy bajo', Color(0xFF38BDF8));
          if (value <= 20) return const _HealthZone('Atlético ✓', Color(0xFF10B981));
          if (value <= 31) return const _HealthZone('Saludable ✓', Color(0xFF10B981));
          if (value <= 36) return const _HealthZone('Por mejorar', Color(0xFFF59E0B));
          return const _HealthZone('Riesgo', Color(0xFFEF4444));
        }

      case BodyCompositionMetric.leanMassKg:
        // Sin referencia universal — mostramos tendencia
        return const _HealthZone('Referencia personal', Color(0xFF2DD4BF));

      case BodyCompositionMetric.waistCm:
        // WHO risk thresholds
        if (isMale) {
          if (value < 94) return const _HealthZone('Zona segura ✓', Color(0xFF10B981));
          if (value < 102) return const _HealthZone('Riesgo moderado', Color(0xFFF59E0B));
          return const _HealthZone('Riesgo alto', Color(0xFFEF4444));
        } else {
          if (value < 80) return const _HealthZone('Zona segura ✓', Color(0xFF10B981));
          if (value < 88) return const _HealthZone('Riesgo moderado', Color(0xFFF59E0B));
          return const _HealthZone('Riesgo alto', Color(0xFFEF4444));
        }

      case BodyCompositionMetric.whtr:
        // Ashwell & Browne 2012: <0.5 saludable
        if (value < 0.5) return const _HealthZone('Saludable ✓', Color(0xFF10B981));
        if (value < 0.6) return const _HealthZone('Riesgo moderado', Color(0xFFF59E0B));
        return const _HealthZone('Riesgo alto', Color(0xFFEF4444));
    }
  }

  double _healthFill(double value, {required bool isMale}) {
    switch (_metric) {
      case BodyCompositionMetric.weight:
        return 0.5; // sin meta de peso en el modelo actual

      case BodyCompositionMetric.bodyFatPct:
        final max = isMale ? 32.0 : 37.0;
        final safe = isMale ? 17.0 : 20.0;
        // Llena de verde hasta safe, luego baja
        if (value <= safe) return 1.0;
        return (1.0 - (value - safe) / (max - safe)).clamp(0.0, 1.0);

      case BodyCompositionMetric.leanMassKg:
        return 0.7; // indicativo

      case BodyCompositionMetric.waistCm:
        final limit = isMale ? 102.0 : 88.0;
        final safe = isMale ? 94.0 : 80.0;
        if (value <= safe) return 1.0;
        return (1.0 - (value - safe) / (limit - safe)).clamp(0.0, 1.0);

      case BodyCompositionMetric.whtr:
        if (value <= 0.5) return 1.0;
        return (1.0 - (value - 0.5) / 0.2).clamp(0.0, 1.0);
    }
  }

  // ─── Texto de feedback ───────────────────────────────────────────────

  String? _feedbackText(
    double current,
    double delta, {
    required bool isMale,
  }) {
    final trend = delta.abs() < 0.05
        ? 'estable'
        : delta < 0
            ? 'bajando'
            : 'subiendo';

    switch (_metric) {
      case BodyCompositionMetric.weight:
        if (delta.abs() < 0.05) {
          return 'Peso estable en el período. Los cambios reales se ven '
              'en semanas y meses, no en días.';
        }
        if (delta < 0) {
          return 'Perdiste ${(-delta).toStringAsFixed(1)} kg en el período. '
              'Continúa con tus 5 pilares para mantener la tendencia.';
        }
        return 'Ganaste ${delta.toStringAsFixed(1)} kg en el período. '
            'Revisa la ventana de alimentación y la hidratación.';

      case BodyCompositionMetric.bodyFatPct:
        final safeMax = isMale ? 24.0 : 31.0;
        if (current <= safeMax) {
          return '% de grasa en zona saludable. Continúa con tus 5 pilares '
              'para mantenerlo o mejorar.';
        }
        return 'Reducir el % de grasa requiere consistencia en ayuno y nutrición. '
            'Tu tendencia va $trend.';

      case BodyCompositionMetric.leanMassKg:
        if (delta > 0.2) {
          return 'Tu masa magra viene aumentando — señal de que el ejercicio '
              'y la nutrición están funcionando.';
        }
        if (delta < -0.2) {
          return 'La masa magra bajó un poco. Revisa tu ingesta de proteína '
              'y la frecuencia de ejercicio.';
        }
        return 'Masa magra estable. El ejercicio de fuerza ayuda a '
            'preservarla durante la pérdida de grasa.';

      case BodyCompositionMetric.waistCm:
        final safe = isMale ? 94.0 : 80.0;
        if (current < safe) {
          return 'Tu cintura está en zona segura. La grasa visceral es '
              'el indicador más importante para la salud metabólica.';
        }
        return 'Reducir la cintura es una de las metas más impactantes. '
            'El ayuno y el ejercicio aeróbico son tus mejores aliados.';

      case BodyCompositionMetric.whtr:
        if (current < 0.5) {
          return 'WHTR en zona saludable (<0.5). Es el indicador más '
              'confiable de riesgo cardiovascular y metabólico.';
        }
        return 'WHTR por encima de 0.5 indica acumulación de grasa '
            'visceral. Prioriza ayuno y actividad física.';
    }
  }
}

// ─── Zona de salud ────────────────────────────────────────────────────────

class _HealthZone {
  final String label;
  final Color color;
  const _HealthZone(this.label, this.color);
}

// ─── Painter del chart ────────────────────────────────────────────────────

class _LinePainter extends CustomPainter {
  final List<double> values;
  final Color accentColor;
  const _LinePainter({required this.values, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.10 : 1.0;
    final yMin = minV - padding;
    final yMax = maxV + padding;
    final yRange = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    double yOf(double v) =>
        size.height - ((v - yMin) / yRange) * size.height;
    double xOf(int i) =>
        values.length == 1 ? size.width / 2 : (i / (values.length - 1)) * size.width;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentColor.withValues(alpha: 0.25),
            accentColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastX = xOf(values.length - 1);
    final lastY = yOf(values.last);
    canvas.drawCircle(Offset(lastX, lastY), 4.0, Paint()..color = accentColor);
    canvas.drawCircle(
      Offset(lastX, lastY),
      6.5,
      Paint()
        ..color = accentColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values || old.accentColor != accentColor;
}

// ─── Helper ───────────────────────────────────────────────────────────────

class _TrendPoint {
  final double value;
  final String dateKey;
  const _TrendPoint({required this.value, required this.dateKey});
}
