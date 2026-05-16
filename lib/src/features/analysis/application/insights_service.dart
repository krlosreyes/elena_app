// SPEC-113: heurísticas que generan los insights a partir del
// histórico del período. Servicio puro — sin Riverpod ni Flutter
// network. Solo recibe la lista de docs y devuelve la lista de
// insights.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/insight.dart';

class InsightsService {
  InsightsService._();

  /// Genera la lista de insights para el período. Si no hay docs,
  /// devuelve un único insight motivacional.
  static List<Insight> generate(List<DailySummaryDoc> docs) {
    if (docs.isEmpty) {
      return const [
        Insight(
          icon: Icons.hourglass_top_rounded,
          accent: Color(0xFF94A3B8),
          title: 'Aún sin data suficiente',
          description:
              'Sigue registrando tus pilares y en pocos días verás insights personalizados.',
        ),
      ];
    }

    final result = <Insight>[];

    // 1. Pilar más constante (mayor cantidad de días ≥80%).
    final pillarStrong = _bestPillar(docs);
    if (pillarStrong != null) {
      result.add(Insight(
        icon: Icons.local_fire_department_rounded,
        accent: AppColors.metabolicGreen,
        title: 'Tu pilar más constante',
        description:
            '${pillarStrong.name}: ${pillarStrong.count}/${docs.length} días al 100%.',
      ));
    }

    // 2. Pilar a trabajar (menor cantidad de días ≥80%).
    final pillarWeak = _worstPillar(docs);
    if (pillarWeak != null && pillarWeak.name != pillarStrong?.name) {
      result.add(Insight(
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFFB923C),
        title: 'Tu pilar a trabajar',
        description:
            '${pillarWeak.name}: solo ${pillarWeak.count}/${docs.length} días al 80%+.',
      ));
    }

    // 3. Mejor día (IMR máximo).
    DailySummaryDoc? best;
    for (final d in docs) {
      if (best == null || d.imrScore > best.imrScore) best = d;
    }
    if (best != null) {
      result.add(Insight(
        icon: Icons.emoji_events_rounded,
        accent: const Color(0xFFFBBF24),
        title: 'Tu mejor día',
        description: '${_humanDate(best.date)} — IMR ${best.imrScore}.',
      ));
    }

    // 4. Promedio del período + tendencia general.
    final avg =
        (docs.fold<int>(0, (acc, d) => acc + d.imrScore) / docs.length).round();
    result.add(Insight(
      icon: Icons.show_chart_rounded,
      accent: const Color(0xFF60A5FA),
      title: 'IMR promedio del período',
      description: '$avg sobre 100 · ${docs.length} días con datos.',
    ));

    return result;
  }

  static _PillarStat? _bestPillar(List<DailySummaryDoc> docs) {
    final counts = _countDaysAt80(docs);
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value == 0) return null;
    return _PillarStat(name: top.key, count: top.value);
  }

  static _PillarStat? _worstPillar(List<DailySummaryDoc> docs) {
    final counts = _countDaysAt80(docs);
    if (counts.isEmpty) return null;
    final sorted = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bottom = sorted.first;
    return _PillarStat(name: bottom.key, count: bottom.value);
  }

  static Map<String, int> _countDaysAt80(List<DailySummaryDoc> docs) {
    final result = <String, int>{
      'Ayuno': 0,
      'Sueño': 0,
      'Hidratación': 0,
      'Ejercicio': 0,
      'Comidas': 0,
    };
    for (final d in docs) {
      if (d.fastingProgress >= 0.8) result['Ayuno'] = result['Ayuno']! + 1;
      if (d.sleepProgress >= 0.8) result['Sueño'] = result['Sueño']! + 1;
      if (d.hydrationProgress >= 0.8) {
        result['Hidratación'] = result['Hidratación']! + 1;
      }
      if (d.exerciseProgress >= 0.8) {
        result['Ejercicio'] = result['Ejercicio']! + 1;
      }
      if (d.mealsProgress >= 0.8) {
        result['Comidas'] = result['Comidas']! + 1;
      }
    }
    return result;
  }

  static String _humanDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final d = int.parse(parts[2]);
      final m = int.parse(parts[1]);
      const months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '$d ${months[m - 1]}';
    } catch (_) {
      return dateKey;
    }
  }
}

class _PillarStat {
  final String name;
  final int count;
  const _PillarStat({required this.name, required this.count});
}
