import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  final FirebaseFirestore _firestore;

  SleepRepositoryImpl(this._firestore);

  @override
  Future<void> saveSleepLog(SleepLog log) async {
    await _firestore
        .collection('users')
        .doc(log.userId)
        .collection('sleep_logs')
        .doc(log.id)
        .set(log.toJson());
  }

  @override
  Future<List<SleepLog>> getRecentSleepLogs(String userId,
      {int limit = 7}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sleep_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => SleepLog.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<SleepLog>> watchRecentSleepLogs(String userId, {int limit = 7}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sleep_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SleepLog.fromJson(doc.data())).toList());
  }
}
