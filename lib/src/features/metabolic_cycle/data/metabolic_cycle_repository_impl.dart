// SPEC-149 §RF-149-05: implementación Firestore del MetabolicCycleRepository.
//
// Subcollection: `users/{uid}/metabolic_cycles/{cycleId}`.
// El cycleId es el ISO timestamp del startedAt en UTC (idempotente
// cross-device).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/metabolic_cycle/data/metabolic_cycle_mapper.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_repository.dart';

class MetabolicCycleRepositoryImpl implements MetabolicCycleRepository {
  MetabolicCycleRepositoryImpl(
    this._firestore, {
    MetabolicCycleMapper mapper = const MetabolicCycleMapper(),
  }) : _mapper = mapper;

  final FirebaseFirestore _firestore;
  final MetabolicCycleMapper _mapper;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('metabolic_cycles');

  @override
  Future<void> save(String userId, MetabolicCycle cycle) async {
    await _col(userId)
        .doc(cycle.cycleId)
        .set(_mapper.toMap(cycle), SetOptions(merge: true));
  }

  @override
  Stream<MetabolicCycle?> watchOpenCycle(String userId) {
    // Firestore no permite filtrar por "closedAt == null" directamente con
    // composite indexes, así que traemos los últimos 5 docs por startedAt
    // desc y filtramos client-side. SPEC-149 garantiza que hay máximo 1
    // ciclo abierto por usuario, pero el filtro defensivo cubre data
    // malformada.
    return _col(userId)
        .orderBy('startedAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final cycle = _mapper.fromMap(Map<String, dynamic>.from(doc.data()));
        if (cycle != null && cycle.isOpen) return cycle;
      }
      return null;
    });
  }

  @override
  Stream<MetabolicCycle?> watchLastClosed(String userId) {
    // Mismo patrón — traemos los últimos por startedAt y filtramos al
    // primero cerrado. Si necesitáramos un index dedicado por closedAt
    // sería un compound (closedAt != null + orderBy closedAt). Por ahora
    // el client-side filter es suficiente.
    return _col(userId)
        .orderBy('startedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final cycle = _mapper.fromMap(Map<String, dynamic>.from(doc.data()));
        if (cycle != null && cycle.isClosed) return cycle;
      }
      return null;
    });
  }

  @override
  Stream<List<MetabolicCycle>> watchRecentClosed(
    String userId, {
    int limit = 90,
  }) {
    return _col(userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                _mapper.fromMap(Map<String, dynamic>.from(doc.data())))
            .whereType<MetabolicCycle>()
            .where((c) => c.isClosed)
            .toList());
  }

  @override
  Future<MetabolicCycle?> fetchOpenCycle(String userId) async {
    final snap = await _col(userId)
        .orderBy('startedAt', descending: true)
        .limit(5)
        .get();
    for (final doc in snap.docs) {
      final cycle = _mapper.fromMap(Map<String, dynamic>.from(doc.data()));
      if (cycle != null && cycle.isOpen) return cycle;
    }
    return null;
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final metabolicCycleRepositoryProvider =
    Provider<MetabolicCycleRepository>((ref) {
  return MetabolicCycleRepositoryImpl(FirebaseFirestore.instance);
});
