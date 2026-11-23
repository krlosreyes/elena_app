// Módulo "Tu Glucosa" — datos de la gráfica histórica (23-nov).
//
// Función pura, sin Flutter: filtra por contexto y ventana, ordena por
// fecha y cuenta cuántas lecturas cayeron en cada rango. La gráfica solo
// pinta lo que sale de aquí, así cada número que ve el usuario se puede
// verificar con un test.
//
// Bandas: son exactamente los cortes de GlucoseClassifier (ADA, Standards
// of Care 2025, sección 2 y sección 6). Un test recorre 40–400 mg/dL y
// confirma que banda y clasificador nunca se contradicen.
//
// Solo hay dos contextos con corte ADA propio: en ayunas y 2 h después de
// comer. Los otros momentos no se grafican con rangos, porque no existe un
// criterio clínico para ellos y no se inventa uno.

import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

/// Contextos que la gráfica muestra, en el orden de las pestañas.
const List<GlucoseReadingContext> kGlucoseChartContexts = [
  GlucoseReadingContext.ayunas,
  GlucoseReadingContext.postprandial2h,
];

/// Ventanas que la gráfica ofrece. El historial se lee a 90 días
/// (`glucoseReadingsProvider`), así que 90 es el máximo honesto.
const List<int> kGlucoseChartWindows = [14, 30, 90];

class GlucoseReferenceBands {
  const GlucoseReferenceBands({
    required this.lowBelow,
    required this.inRangeBelow,
    required this.highFrom,
  });

  /// Por debajo: "Bajo" (ADA: hipoglucemia nivel 1, < 70 mg/dL).
  final int lowBelow;

  /// Por debajo (y desde [lowBelow]): "En rango".
  final int inRangeBelow;

  /// Desde aquí: "Alto". Entre [inRangeBelow] y [highFrom] − 1: "Elevado".
  final int highFrom;

  /// Cortes por contexto. `null` = el contexto no tiene corte ADA.
  static GlucoseReferenceBands? forContext(GlucoseReadingContext context) {
    switch (context) {
      case GlucoseReadingContext.ayunas:
        return const GlucoseReferenceBands(
            lowBelow: 70, inRangeBelow: 100, highFrom: 126);
      case GlucoseReadingContext.postprandial2h:
        return const GlucoseReferenceBands(
            lowBelow: 70, inRangeBelow: 140, highFrom: 200);
      case GlucoseReadingContext.antesDeComer:
      case GlucoseReadingContext.postprandial1h:
      case GlucoseReadingContext.antesDeDormir:
      case GlucoseReadingContext.otro:
        return null;
    }
  }

  GlucoseClassification classify(int v) {
    if (v < lowBelow) return GlucoseClassification.bajo;
    if (v < inRangeBelow) return GlucoseClassification.enRango;
    if (v < highFrom) return GlucoseClassification.elevado;
    return GlucoseClassification.alto;
  }
}

class GlucoseChartPoint {
  const GlucoseChartPoint({
    required this.at,
    required this.valueMgDl,
    required this.classification,
  });

  final DateTime at;
  final int valueMgDl;
  final GlucoseClassification classification;
}

class GlucoseChartData {
  const GlucoseChartData({
    required this.context,
    required this.bands,
    required this.windowStart,
    required this.windowEnd,
    required this.points,
  });

  final GlucoseReadingContext context;
  final GlucoseReferenceBands bands;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// De la más vieja a la más nueva.
  final List<GlucoseChartPoint> points;

  bool get isEmpty => points.isEmpty;
  int get count => points.length;

  int countOf(GlucoseClassification c) =>
      points.where((p) => p.classification == c).length;

  int get inRangeCount => countOf(GlucoseClassification.enRango);

  /// Porcentaje entero de lecturas en rango (null sin lecturas).
  int? get inRangePercent =>
      count == 0 ? null : (inRangeCount * 100 / count).round();

  double? get mean => count == 0
      ? null
      : points.map((p) => p.valueMgDl).reduce((a, b) => a + b) / count;

  int? get minValue => count == 0
      ? null
      : points.map((p) => p.valueMgDl).reduce((a, b) => a < b ? a : b);

  int? get maxValue => count == 0
      ? null
      : points.map((p) => p.valueMgDl).reduce((a, b) => a > b ? a : b);

  /// Arma la serie. Devuelve null si [context] no tiene corte ADA.
  /// Descarta lecturas fuera del rango plausible del glucómetro (R9) y
  /// las que estén fuera de la ventana `(now − windowDays, now]`.
  static GlucoseChartData? build({
    required List<GlucoseReading> readings,
    required GlucoseReadingContext context,
    required int windowDays,
    required DateTime now,
  }) {
    final bands = GlucoseReferenceBands.forContext(context);
    if (bands == null) return null;
    final start = now.subtract(Duration(days: windowDays));
    final selected = readings
        .where((r) =>
            r.context == context &&
            r.isPlausible &&
            r.measuredAt.isAfter(start) &&
            !r.measuredAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    return GlucoseChartData(
      context: context,
      bands: bands,
      windowStart: start,
      windowEnd: now,
      points: [
        for (final r in selected)
          GlucoseChartPoint(
            at: r.measuredAt,
            valueMgDl: r.valueMgDl,
            classification: GlucoseClassifier.classify(r.valueMgDl, context),
          ),
      ],
    );
  }
}
