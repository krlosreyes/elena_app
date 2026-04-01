import '../entities/sleep_log.dart';

abstract class SleepRepository {
  Future<void> saveSleepLog(SleepLog log);
  Future<List<SleepLog>> getRecentSleepLogs(String userId, {int limit = 7});
  Stream<List<SleepLog>> watchRecentSleepLogs(String userId, {int limit = 7});
}
