import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/imx_engine.dart';
import '../domain/imx_model.dart';
import '../../profile/domain/user_model.dart';
import '../../fasting/domain/fasting_session.dart';
import '../../progress/domain/measurement_log.dart';

class ImxRepository {
  final SharedPreferences _prefs;
  final String _functionUrl = 'https://us-central1-elena-app-2026-v1.cloudfunctions.net/calculateIMXv2';

  static const String _cacheKey = 'last_imx_result';

  ImxRepository({
    required SharedPreferences prefs,
  })  : _prefs = prefs;

  /// Fetch IMX Score from Cloud Function with local cache fallback
  Future<ImxResult> fetchIMXScore({
    required UserModel user,
    required List<FastingSession> recentSessions,
    double? fastingHours24h,
    int? fastingDaysPlanned,
    int? fastingDaysCompleted,
    double? activityMinutes,
    double? sleepHours,
  }) async {
    try {
      // 1. Prepare Payload (Matching the new JS implementation)
      final bodyFat = MeasurementLog.calculateBodyFat(
        heightCm: user.heightCm,
        waistCm: user.waistCircumferenceCm,
        neckCm: user.neckCircumferenceCm,
        hipCm: user.hipCircumferenceCm,
        isMale: user.gender == Gender.male,
      ) ?? 20.0;

      final payload = {
        'currentWeightKg': user.currentWeightKg,
        'heightCm': user.heightCm,
        'waistCircumferenceCm': user.waistCircumferenceCm,
        'neckCircumferenceCm': user.neckCircumferenceCm,
        'hipCircumferenceCm': user.hipCircumferenceCm,
        'genero': user.gender == Gender.male ? 'male' : 'female',
        'fastingHours': recentSessions.isNotEmpty 
            ? (recentSessions.first.endTime?.difference(recentSessions.first.startTime).inHours ?? recentSessions.first.plannedDurationHours) 
            : 16,
        'averageSleepHours': user.averageSleepHours ?? 7,
      };

      // 2. Call Cloud Function via HTTP POST
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch IMX: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final breakdown = data['breakdown'] ?? {};
      
      // 3. Map to ImxResult structure
      final imxResult = ImxResult(
        total: (double.tryParse(data['score']?.toString() ?? '50') ?? 50.0), // Escala 0-100
        scoreStructure: (double.tryParse(breakdown['structure']?.toString() ?? '0.5') ?? 0.5) * 100,
        scoreMetabolic: (double.tryParse(breakdown['metabolic']?.toString() ?? '0.5') ?? 0.5) * 100,
        scoreBehavior: (double.tryParse(breakdown['behavior']?.toString() ?? '0.5') ?? 0.5) * 100,
        category: data['category'] ?? 'Funcional',
        categoryType: _mapCategoryType(data['category'] ?? ''),
        bodyFat: bodyFat,
        ffmi: (bodyFat > 0) ? (user.currentWeightKg * (1 - (bodyFat / 100))) / (user.heightCm / 100 * user.heightCm / 100) : 0.0,
        leanMassKg: user.currentWeightKg * (1 - (bodyFat / 100)),
        calculatedAt: DateTime.now(),
      );

      await _cacheResult(imxResult);
      return imxResult;
    } catch (e) {
      // 4. Fallback to Cache on failure
      final cached = _getCachedResult();
      if (cached != null) {
        return cached;
      }
      return ImxResult.empty;
    }
  }

  String _mapCategoryType(String category) {
    if (category.contains('Sarcopenia')) return 'deteriorated';
    if (category.contains('Atleta')) return 'optimized';
    return 'functional';
  }

  /// Persistence methods for ImxService (Legacy/Bridge compatibility)
  Future<ImxModel?> getLatestImx(String uid) async {
    // For now, return null as we are transitioning to Motor v2
    // In a real scenario, this would fetch from Firestore 'imx_calculations'
    return null;
  }

  Future<void> saveImxCalculation(String uid, ImxModel imx) async {
    // Stub for saving old ImxModel to Firestore
  }

  Future<void> _cacheResult(ImxResult result) async {
    final jsonStr = jsonEncode(result.toJson());
    await _prefs.setString(_cacheKey, jsonStr);
  }

  ImxResult? _getCachedResult() {
    final jsonStr = _prefs.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      return ImxResult.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }
}
