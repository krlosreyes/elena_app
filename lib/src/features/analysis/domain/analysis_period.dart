// SPEC-113: enumeración de los rangos temporales disponibles en la
// pantalla Análisis. Cada uno expone su duración en días y un label
// legible.

enum AnalysisPeriod {
  week(days: 7, label: 'Semana'),
  month(days: 30, label: 'Mes'),
  threeMonths(days: 90, label: '3 Meses');

  const AnalysisPeriod({required this.days, required this.label});

  final int days;
  final String label;
}
