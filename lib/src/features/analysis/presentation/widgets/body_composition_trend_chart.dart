// SPEC-152: widget de tendencia de composición corporal en Análisis.
//
// Una métrica a la vez (tab Peso/Cintura/Grasa). Período 30/60/90 días.
// Resuelve la deuda visible "Análisis vacía" registrada tras SPEC-143.
//
// Layout: header con tabs + selector, valor grande con delta, mini
// line chart con CustomPaint.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/biometric_trend_provider.dart';
import 'package:elena_app/src/features/analysis/domain/body_composition_metric.dart';
// SPEC-168.4.4: silueta humana abajo del chart, tintada por zona ACSM.
import 'package:elena_app/src/features/analysis/presentation/widgets/body_silhouette.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class BodyCompositionTrendChart extends ConsumerStatefulWidget {
  const BodyCompositionTrendChart({super.key});

  @override
  ConsumerState<BodyCompositionTrendChart> createState() =>
      _BodyCompositionTrendChartState();
}

class _BodyCompositionTrendChartState
    extends ConsumerState<BodyCompositionTrendChart> {
  BodyCompositionMetric _metric = BodyCompositionMetric.weight;
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final asyncCheckIns = ref.watch(biometricTrendProvider(_days));
    // SPEC-157: necesitamos height para WHTR. Watch del user provider.
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final heightCm = (user?.height ?? 0) > 0 ? user!.height : null;
    // SPEC-168.4.4: zona ACSM para la silueta. Usamos el % grasa
    // persistido en el UserProfile (más fresco que el último check-in
    // del rango). Género normalizado a "M" => isMale=true.
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
          const SizedBox(height: 12),
          _buildPeriodSelector(),
          const SizedBox(height: 18),
          asyncCheckIns.when(
            loading: () => _buildLoading(),
            error: (_, __) => _buildErrorBox(),
            data: (list) => _buildContent(list, heightCm: heightCm),
          ),
          // SPEC-168.4.4: silueta humana tintada por zona ACSM. Se
          // muestra siempre — tanto con datos como sin ellos, en el
          // segundo caso con copy de "Registrá tu % de grasa para...".
          const SizedBox(height: 28),
          Center(
            child: BodySilhouette(
              bodyFatPct: bodyFatPct,
              isMale: isMale,
            ),
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

  // ─── Tabs de métrica ────────────────────────────────────────────────

  Widget _buildMetricTabs() {
    // SPEC-157: 5 tabs ya no entran en pantallas chicas. Scroll
    // horizontal para acomodar sin acumular alto vertical.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BodyCompositionMetric.values.map((m) {
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
                  m.label,
                  style: TextStyle(
                    color: isSelected ? m.accentColor : Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Selector de período ────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Row(
      children: kBiometricTrendWindowDays.map((d) {
        final isSelected = d == _days;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _days = d),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${d}d',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Estados de contenido ───────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.metabolicGreen,
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Text(
        'No pudimos cargar la tendencia.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildContent(List<BiometricCheckIn> all, {double? heightCm}) {
    // Extraer solo los valores no-null para la métrica seleccionada.
    // SPEC-157: WHTR depende de heightCm; las otras métricas lo ignoran.
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
        _buildValueHeadline(last.value, delta),
        const SizedBox(height: 14),
        _buildChart(samples),
        const SizedBox(height: 8),
        _buildAxisLabels(samples.length),
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
            : 'Necesitamos al menos 2 mediciones — registrate otra vez.',
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

  // ─── Valor + delta ──────────────────────────────────────────────────

  Widget _buildValueHeadline(double currentValue, double delta) {
    // Color del delta según dirección. SPEC-152 §2.4:
    // ↓ verde = bajó, ↑ ámbar = subió, sin valoración moral.
    Color deltaColor;
    IconData deltaIcon;
    if (delta < -0.05) {
      deltaColor = AppColors.metabolicGreen;
      deltaIcon = Icons.arrow_downward_rounded;
    } else if (delta > 0.05) {
      deltaColor = const Color(0xFFF59E0B);
      deltaIcon = Icons.arrow_upward_rounded;
    } else {
      deltaColor = Colors.white.withValues(alpha: 0.45);
      deltaIcon = Icons.remove_rounded;
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
                fontFamily: 'monospace',
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
              '${_metric.deltaCopyFor(delta)} en $_days días',
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

  // ─── Chart ──────────────────────────────────────────────────────────

  Widget _buildChart(List<_TrendPoint> samples) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: CustomPaint(
        painter: _BodyCompositionTrendPainter(
          values: samples.map((s) => s.value).toList(),
          accentColor: _metric.accentColor,
        ),
      ),
    );
  }

  Widget _buildAxisLabels(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_days días atrás',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          'hoy',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Painter del chart ─────────────────────────────────────────────────

class _BodyCompositionTrendPainter extends CustomPainter {
  _BodyCompositionTrendPainter({
    required this.values,
    required this.accentColor,
  });

  final List<double> values;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    // Padding del eje Y: 10% del rango si hay rango, fallback ±1.
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.10 : 1.0;
    final yMin = minV - padding;
    final yMax = maxV + padding;
    final yRange = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    // Mapeo de valor a y (invertido: y=0 es arriba en Flutter).
    double yOf(double v) {
      final normalized = (v - yMin) / yRange;
      return size.height - (normalized * size.height);
    }

    // Mapeo de índice a x (distribución uniforme).
    double xOf(int i) {
      if (values.length == 1) return size.width / 2;
      return (i / (values.length - 1)) * size.width;
    }

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

    // Gradient de relleno sutil debajo de la línea.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accentColor.withValues(alpha: 0.25),
          accentColor.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Línea principal.
    final linePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Puntos: solo el último — feedback de "donde estás ahora".
    final lastX = xOf(values.length - 1);
    final lastY = yOf(values.last);
    canvas.drawCircle(
      Offset(lastX, lastY),
      4.0,
      Paint()..color = accentColor,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      6.5,
      Paint()
        ..color = accentColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyCompositionTrendPainter old) =>
      old.values != values || old.accentColor != accentColor;
}

// ─── Helper ─────────────────────────────────────────────────────────────

class _TrendPoint {
  final double value;
  final String dateKey;
  const _TrendPoint({required this.value, required this.dateKey});
}
