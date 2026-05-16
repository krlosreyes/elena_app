// SPEC-111: traduce entre el DailySummary del dominio y el doc
// persistible. Centraliza la conversión a/desde Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';

class DailySummaryMapper {
  const DailySummaryMapper();

  /// Construye un Doc a partir del summary in-memory + la fecha.
  /// `now` se inyecta para testabilidad.
  DailySummaryDoc toDoc({
    required DailySummary summary,
    required DateTime now,
  }) {
    return DailySummaryDoc(
      date: _dateKey(now),
      imrScore: summary.imrScore,
      fastingProgress: summary.fastingProgress,
      sleepProgress: summary.sleepProgress,
      hydrationProgress: summary.hydrationProgress,
      exerciseProgress: summary.exerciseProgress,
      mealsProgress: summary.mealsProgress,
      updatedAt: now,
    );
  }

  /// Convierte el doc a un Map listo para Firestore.
  Map<String, dynamic> toMap(DailySummaryDoc doc) {
    return {
      'date': doc.date,
      'imrScore': doc.imrScore,
      'fastingProgress': doc.fastingProgress,
      'sleepProgress': doc.sleepProgress,
      'hydrationProgress': doc.hydrationProgress,
      'exerciseProgress': doc.exerciseProgress,
      'mealsProgress': doc.mealsProgress,
      'updatedAt': Timestamp.fromDate(doc.updatedAt),
      'schemaVersion': doc.schemaVersion,
    };
  }

  /// Parsea un Map crudo de Firestore al Doc del dominio.
  /// Tolerante a campos faltantes — degrada graciosamente para docs
  /// pre-schema-v1 (improbable, pero defensivo).
  DailySummaryDoc fromMap(Map<String, dynamic> map) {
    return DailySummaryDoc(
      date: map['date'] as String? ?? '',
      imrScore: (map['imrScore'] as num?)?.toInt() ?? 0,
      fastingProgress: (map['fastingProgress'] as num?)?.toDouble() ?? 0.0,
      sleepProgress: (map['sleepProgress'] as num?)?.toDouble() ?? 0.0,
      hydrationProgress: (map['hydrationProgress'] as num?)?.toDouble() ?? 0.0,
      exerciseProgress: (map['exerciseProgress'] as num?)?.toDouble() ?? 0.0,
      mealsProgress: (map['mealsProgress'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
    );
  }

  /// Doc id canónico = `YYYYMMDD` (sin guiones para que sea válido
  /// como id de Firestore).
  static String docIdFor(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Formato de fecha legible `YYYY-MM-DD` (con guiones) que se
  /// guarda como campo `date` dentro del doc.
  String _dateKey(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
