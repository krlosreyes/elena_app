// Módulo "Tu Glucosa" — pantalla de detalle (propuesta §7.3).
// Mismo AppBar/Scaffold que RachaDetailScreen (analysis/presentation/
// racha_detail_screen.dart) — back button + título simple, sin
// reinventar el patrón de las pantallas de detalle de Progreso.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_variability.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_chart.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_insight_card.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_reading_sheet.dart';

class GlucoseDetailScreen extends ConsumerWidget {
  const GlucoseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingsAsync = ref.watch(glucoseReadingsProvider);
    final variability = ref.watch(glucoseAyunasVariabilityProvider);
    final insights = ref.watch(glucoseInsightsProvider);

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
        title: const Text(
          'Tu Glucosa',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: Colors.white, size: 22),
            tooltip: 'Registrar lectura',
            onPressed: () => showGlucoseReadingSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: readingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              'No pudimos cargar tu historial. Intenta de nuevo más tarde.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          data: (readings) {
            if (readings.isEmpty) {
              return _EmptyState(
                onRegister: () => showGlucoseReadingSheet(context),
              );
            }

            final ayunas = readings
                .where((r) => r.context == GlucoseReadingContext.ayunas)
                .toList()
                .reversed // Firestore viene desc; el chart quiere asc.
                .toList();
            final last = readings.first;
            final avg7 = _average(readings, days: 7);
            final classification =
                GlucoseClassifier.classify(last.valueMgDl, last.context);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _SummaryRow(
                  last: last,
                  classification: classification,
                  avg7: avg7,
                  variability: variability,
                ),
                const SizedBox(height: 20),
                Text(
                  'HISTÓRICO (AYUNAS)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GlucoseChart(readings: ayunas),
                ),
                const SizedBox(height: 24),
                Text(
                  'CÓMO TUS HÁBITOS AFECTAN TU GLUCOSA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 10.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (insights.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Todavía no tenemos suficientes datos para mostrarte '
                      'un patrón confiable. Sigue registrando tu glucosa '
                      'unos días más — necesitamos al menos una semana de '
                      'superposición con tus otros hábitos.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  ...insights.map((i) => GlucoseInsightCard(insight: i)),
                const SizedBox(height: 24),
                const _EducationSection(),
                const SizedBox(height: 20),
                _DisclaimerFooter(),
              ],
            );
          },
        ),
      ),
    );
  }

  double? _average(List<GlucoseReading> readings, {required int days}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final inWindow = readings
        .where((r) =>
            r.context == GlucoseReadingContext.ayunas &&
            r.measuredAt.isAfter(cutoff))
        .map((r) => r.valueMgDl)
        .toList();
    if (inWindow.isEmpty) return null;
    return inWindow.reduce((a, b) => a + b) / inWindow.length;
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.last,
    required this.classification,
    required this.avg7,
    required this.variability,
  });

  final GlucoseReading last;
  final GlucoseClassification classification;
  final double? avg7;
  final GlucoseVariabilityResult variability;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'ÚLTIMA',
            value: '${last.valueMgDl}',
            unit: 'mg/dL',
            caption: classification == GlucoseClassification.sinUmbral
                ? last.context.label
                : classification.label,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'PROMEDIO 7D (AYUNAS)',
            value: avg7 == null ? '—' : avg7!.round().toString(),
            unit: avg7 == null ? '' : 'mg/dL',
            caption: avg7 == null ? 'Sin datos' : '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'VARIABILIDAD',
            value: variability.hasEnoughData
                ? '${variability.coefficientOfVariationPercent.round()}%'
                : '—',
            unit: '',
            caption: !variability.hasEnoughData
                ? 'Necesita más datos'
                : (variability.isHighVariability ? 'Alta' : 'Estable'),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });

  final String label;
  final String value;
  final String unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 8.5,
              letterSpacing: 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Para entender tus números',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _EducationItem(
            title: 'Variabilidad glucémica',
            body: 'Qué tanto sube y baja tu glucosa, más allá del '
                'promedio. Un poco de variación es normal — se marca '
                '"alta" solo cuando supera un umbral usado en consenso '
                'internacional de monitoreo (Monnier et al., Diabetes '
                'Care 2017).',
          ),
          const SizedBox(height: 10),
          _EducationItem(
            title: 'Fenómeno del alba',
            body: 'Es normal que la glucosa suba un poco antes de '
                'despertar por cambios hormonales naturales — no '
                'significa que algo esté mal. Es distinto del "efecto '
                'Somogyi" (una hipótesis clásica de 1938 sobre rebote '
                'tras una baja nocturna) que hoy está en revisión: '
                'estudios recientes con monitoreo continuo no confirman '
                'que ocurra de forma consistente. Si tu glucosa matutina '
                'te preocupa, es un buen tema para tu próxima consulta.',
          ),
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  const _EducationItem({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DisclaimerFooter extends StatelessWidget {
  const _DisclaimerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: Colors.white.withValues(alpha: 0.4), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esto es una herramienta de acompañamiento, no un '
              'diagnóstico ni un reemplazo de tu HbA1c o el criterio de '
              'tu médico.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_outlined,
                color: Colors.white.withValues(alpha: 0.25), size: 48),
            const SizedBox(height: 16),
            Text(
              'Todavía no registraste ninguna lectura de glucosa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.metabolicGreen,
                foregroundColor: Colors.black,
              ),
              child: const Text('Registrar mi primera lectura'),
            ),
          ],
        ),
      ),
    );
  }
}
