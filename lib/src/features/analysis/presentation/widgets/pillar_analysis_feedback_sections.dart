import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/application/goal_for_chart_provider.dart';
import 'package:elena_app/src/features/analysis/application/historic_summaries_provider.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/ayuno_feedback_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/imr_pillar_feedback_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/pillar_feedback_card.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// SPEC-119: extraído de `_imrFeedbackCard`, `_ayunoFeedbackCard`,
/// `_hidratacionFeedbackCard`, `_ejercicioFeedbackCard`,
/// `_suenoFeedbackCard` y `_nutricionFeedbackCard` en
/// `analysis_pillar_detail_screen.dart` (ARCH-03). Cada método era
/// autocontenido (solo dependía de `ref`), así que pasan a ser
/// `ConsumerWidget` sin parámetros. `_isoDate` y `_protocolHours`
/// (helpers privados usados solo por estos métodos) se copiaron
/// exactos junto con el código que los usa.

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

double _protocolHours(String protocol) {
  switch (protocol) {
    case '18:6':
      return 18.0;
    case '20:4':
      return 20.0;
    case 'Ninguno':
      return 12.0;
    default:
      return 16.0; // 16:8 default
  }
}

/// Card de feedback de pilares para la sección IMR.
class ImrPillarFeedbackSection extends ConsumerWidget {
  const ImrPillarFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(analysisRangeStartProvider);
    final today = DateTime.now();
    final docsAsync = ref.watch(
      historicSummariesProvider(
        HistoricSummariesRange(
          fromIncl: _isoDate(start),
          toIncl: _isoDate(today),
        ),
      ),
    );
    final docs = docsAsync.value;
    if (docs == null || docs.isEmpty) return const SizedBox.shrink();
    return ImrPillarFeedbackCard(docs: docs);
  }
}

/// Card de feedback de hábito de ayuno.
class AyunoPillarFeedbackSection extends ConsumerWidget {
  const AyunoPillarFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(fastingHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();
    // fastingProtocol es String: '16:8' | '18:6' | '20:4' | 'Ninguno'
    // PERF-01: solo se usa `fastingProtocol` del usuario — se selecciona
    // ese campo puntual en vez de observar el AsyncValue<UserModel> entero.
    final protocol = ref.watch(currentUserStreamProvider
        .select((asyncUser) => asyncUser.valueOrNull?.fastingProtocol));
    final targetHours = _protocolHours(protocol ?? '16:8');
    return AyunoFeedbackCard(series: series, targetHours: targetHours);
  }
}

/// Hidratación: PROMEDIO litros | EN OBJETIVO días | CUMPLIMIENTO %.
/// Target = goal del usuario o 2.5 L por defecto.
class HidratacionFeedbackSection extends ConsumerWidget {
  const HidratacionFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(hydrationHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw =
        ref.watch(goalForChartProvider(ChartMetric.hydrationLiters));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 2.5;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Excelente hidratación';
      body = 'Estás cumpliendo tu objetivo de ${target.toStringAsFixed(1)} L '
          'la mayoría de los días. El agua potencia la termogénesis celular '
          'y mejora el transporte de nutrientes.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} L está cerca del '
          'objetivo. Añadir un vaso de agua al despertar y antes de cada '
          'comida puede sumar hasta 0.6 L sin esfuerzo.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} L está por debajo de '
          '${target.toStringAsFixed(1)} L. La deshidratación leve reduce el '
          'metabolismo y puede confundirse con hambre. Apunta a ${target.toStringAsFixed(1)} L diarios.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE HIDRATACIÓN',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.toStringAsFixed(1)} L',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / (target * 1.5)).clamp(0.0, 1.0),
      progressColor: const Color(0xFF38BDF8),
      progressLeft: '0 L',
      progressRight: '${(target * 1.5).toStringAsFixed(1)} L',
      markerFraction: (target / (target * 1.5)).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.toStringAsFixed(1)} L',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }
}

/// Ejercicio: PROMEDIO minutos | EN OBJETIVO días | CUMPLIMIENTO %.
/// Target = goal del usuario o 30 min por defecto.
class EjercicioFeedbackSection extends ConsumerWidget {
  const EjercicioFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(exerciseHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw = ref.watch(goalForChartProvider(ChartMetric.exerciseMin));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 30.0;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Excelente actividad física';
      body = 'Estás cumpliendo tus ${target.round()} min de ejercicio '
          'la mayoría de los días. La actividad física regular optimiza la '
          'sensibilidad a la insulina y acelera el metabolismo en reposo.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.round()} min está cerca del objetivo. '
          'Agregar 5–10 min a tus sesiones actuales es suficiente para '
          'cruzar al rango de beneficio metabólico comprobado.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.round()} min está por debajo de '
          '${target.round()} min. Incluso 15–20 min de caminata intensa '
          'activan la quema de grasa y mejoran los marcadores hormonales.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE EJERCICIO',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.round()} min',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / (target * 1.5)).clamp(0.0, 1.0),
      progressColor: const Color(0xFFEF4444),
      progressLeft: '0 min',
      progressRight: '${(target * 1.5).round()} min',
      markerFraction: (target / (target * 1.5)).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.round()} min',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }
}

/// Sueño: PROMEDIO horas | EN OBJETIVO días | CUMPLIMIENTO %.
/// Target = goal del usuario o 8 h por defecto.
class SuenoFeedbackSection extends ConsumerWidget {
  const SuenoFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sleepHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    final goalRaw = ref.watch(goalForChartProvider(ChartMetric.sleepHours));
    final target = (goalRaw != null && goalRaw > 0) ? goalRaw : 8.0;

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;
    // Barra: 0h → 10h (máx razonable)
    const barMax = 10.0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Sueño reparador consistente';
      body = 'Estás logrando ${target.toStringAsFixed(1)} h de sueño '
          'la mayoría de los días. Un sueño adecuado regula la grelina y '
          'la leptina — las hormonas del hambre — y optimiza la recuperación '
          'muscular.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} h está cerca del '
          'objetivo. Establecer un horario de sueño fijo y evitar pantallas '
          '1 h antes de dormir puede sumar 30–60 min de calidad.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.toStringAsFixed(1)} h está por debajo de '
          '${target.toStringAsFixed(1)} h. El déficit crónico de sueño '
          'eleva el cortisol y puede ralentizar la pérdida de grasa, '
          'incluso con dieta y ejercicio correctos.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE SUEÑO',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.toStringAsFixed(1)} h',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'EN OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / barMax).clamp(0.0, 1.0),
      progressColor: const Color(0xFF818CF8),
      progressLeft: '0 h',
      progressRight: '${barMax.round()} h',
      markerFraction: (target / barMax).clamp(0.0, 1.0),
      markerLabel: 'Objetivo: ${target.toStringAsFixed(1)} h',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }
}

/// Nutrición: PROMEDIO % A-dominante | DÍAS OBJETIVO | CUMPLIMIENTO %.
/// Target científico: ≥70 % A-dominante por período.
class NutricionFeedbackSection extends ConsumerWidget {
  const NutricionFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(nutritionHabitSeriesProvider);
    final series = s.valueOrNull;
    if (series == null || series.points.isEmpty) return const SizedBox.shrink();

    const target = 70.0; // % A-dominante objetivo (fundamento hormonal)

    final points = series.points.where((p) => p.sampleCount > 0).toList();
    if (points.isEmpty) return const SizedBox.shrink();

    final avg = points.fold<double>(0, (a, b) => a + b.value) / points.length;
    final daysOnTarget = points.where((p) => p.value >= target).length;
    final total = points.length;
    final pct = total > 0 ? (daysOnTarget / total * 100).round() : 0;

    final Color color;
    final String emoji, title, body;
    if (avg >= target && pct >= 70) {
      color = const Color(0xFF10B981);
      emoji = '🏆';
      title = 'Nutrición A-dominante';
      body = 'Tu alimentación es mayoritariamente de Tipo A: alimentos que '
          'bajan la glucosa y favorecen la quema de grasa. Esto reduce la '
          'inflamación sistémica y optimiza el perfil hormonal metabólico.';
    } else if (avg >= target * 0.75) {
      color = const Color(0xFF38BDF8);
      emoji = '📈';
      title = 'En progreso';
      body = 'Tu promedio de ${avg.round()} % A-dominante está cerca del '
          'objetivo de 70 %. Reemplazar una comida E por una opción A cada '
          'día puede marcar una diferencia visible en 2–3 semanas.';
    } else {
      color = const Color(0xFFF59E0B);
      emoji = '🎯';
      title = 'Oportunidad de mejora';
      body = 'Tu promedio de ${avg.round()} % A-dominante indica que los '
          'alimentos tipo E están predominando. Prioriza proteínas magras, '
          'vegetales y grasas saludables para activar la termogénesis y '
          'estabilizar la insulina.';
    }

    return PillarFeedbackCard(
      headerLabel: 'ANÁLISIS DE NUTRICIÓN',
      chips: [
        (
          label: 'PROMEDIO',
          value: '${avg.round()} % A',
          color: avg >= target
              ? const Color(0xFF10B981)
              : avg >= target * 0.75
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'DÍAS OBJETIVO',
          value: '$daysOnTarget/$total días',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
        (
          label: 'CUMPLIMIENTO',
          value: '$pct%',
          color: pct >= 70
              ? const Color(0xFF10B981)
              : pct >= 40
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFF59E0B),
        ),
      ],
      progressFill: (avg / 100.0).clamp(0.0, 1.0),
      progressColor: const Color(0xFFF59E0B),
      progressLeft: '0 %',
      progressRight: '100 %',
      markerFraction: target / 100.0,
      markerLabel: 'Objetivo: ≥${target.round()} % A-dominante',
      statusEmoji: emoji,
      statusTitle: title,
      statusColor: color,
      statusBody: body,
    );
  }
}
