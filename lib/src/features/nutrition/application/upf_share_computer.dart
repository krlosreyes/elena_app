// SPEC-138: motor puro del indicador UPF (% ultra-procesados).
//
// Dado un conjunto de NutritionLog, computa el % UPF agregado del
// período. Pure Dart — sin Flutter ni Riverpod ni IO.
//
// Marco normativo: docs/NUTRITION_BIBLIOGRAPHY.md §16.

import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Resultado del cómputo agregado.
///
/// `confidence` indica si tenemos suficientes datos NOVA para que el
/// porcentaje sea accionable (ver `UpfThresholds.weeklyMinLogsWithNova`).
class UpfShareResult {
  /// Porcentaje UPF agregado del período (0-100). 0 si no hay logs
  /// con datos NOVA (semantic: "aún no sabemos", no "sin UPF").
  final int sharePercent;

  /// Cuántos slots UPF acumulados.
  final int upfSlots;

  /// Cuántos slots totales acumulados.
  final int totalSlots;

  /// Cuántos logs del período aportaron datos NOVA (no-null en
  /// `upfSlots`/`totalSlots`). Si bajo del umbral, el insight de
  /// coaching debe ABSTENERSE — no opinamos con datos pobres.
  final int logsWithNova;

  /// Total de logs del período (con o sin NOVA). Útil para contexto.
  final int totalLogs;

  const UpfShareResult({
    required this.sharePercent,
    required this.upfSlots,
    required this.totalSlots,
    required this.logsWithNova,
    required this.totalLogs,
  });

  /// Resultado neutro para períodos sin datos NOVA.
  const UpfShareResult.empty({this.totalLogs = 0})
      : sharePercent = 0,
        upfSlots = 0,
        totalSlots = 0,
        logsWithNova = 0;

  /// True si el resultado es accionable (≥ [minLogsWithNova] logs con
  /// datos NOVA). Bajo este umbral, ningún insight se debe disparar.
  bool isActionable({required int minLogsWithNova}) =>
      logsWithNova >= minLogsWithNova;
}

class UpfShareComputer {
  UpfShareComputer._();

  /// Agrega los logs del período. Logs con `upfSlots`/`totalSlots` null
  /// se ignoran del cálculo del porcentaje (pero se cuentan en
  /// `totalLogs` para que el caller sepa la composición real).
  ///
  /// Logs marcados `isCheatDay=true` SÍ cuentan hacia el % UPF — el
  /// patrón del cuerpo no distingue intención. Sí se podrían excluir
  /// del cómputo si el comité médico lo prefiere (decisión abierta
  /// en §16.7 de la bibliografía).
  static UpfShareResult compute(List<NutritionLog> logs) {
    if (logs.isEmpty) return const UpfShareResult.empty();

    int upf = 0;
    int total = 0;
    int logsWithNova = 0;

    for (final log in logs) {
      final u = log.upfSlots;
      final t = log.totalSlots;
      if (u == null || t == null || t == 0) continue;
      upf += u;
      total += t;
      logsWithNova += 1;
    }

    if (total == 0) {
      return UpfShareResult.empty(totalLogs: logs.length);
    }

    final pct = ((upf / total) * 100).round();
    return UpfShareResult(
      sharePercent: pct,
      upfSlots: upf,
      totalSlots: total,
      logsWithNova: logsWithNova,
      totalLogs: logs.length,
    );
  }
}
