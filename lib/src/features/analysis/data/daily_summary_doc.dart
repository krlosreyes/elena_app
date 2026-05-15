// SPEC-111: representación persistible del DailySummary.
//
// El `DailySummary` (domain) vive en memoria y se computa cada vez
// que un pilar emite. `DailySummaryDoc` (data) es la versión que se
// escribe/lee de Firestore — agrega fecha calendario, timestamp de
// actualización y versión de schema para evolución segura.

class DailySummaryDoc {
  /// Fecha en formato `YYYY-MM-DD` (UTC del usuario para evitar
  /// confusiones por timezone).
  final String date;
  final int imrScore;
  final double fastingProgress;
  final double sleepProgress;
  final double hydrationProgress;
  final double exerciseProgress;
  final double mealsProgress;

  /// Timestamp del último upsert. Lo escribe el data source.
  final DateTime updatedAt;

  /// Versión del schema. Permite migraciones futuras sin breaking.
  final int schemaVersion;

  const DailySummaryDoc({
    required this.date,
    required this.imrScore,
    required this.fastingProgress,
    required this.sleepProgress,
    required this.hydrationProgress,
    required this.exerciseProgress,
    required this.mealsProgress,
    required this.updatedAt,
    this.schemaVersion = 1,
  });
}
