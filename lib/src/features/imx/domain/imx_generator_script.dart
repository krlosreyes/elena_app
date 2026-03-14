import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'imx_calculator.dart';

class ImxDataGenerator {
  static final _random = Random();

  static Future<void> generateAndInject50Profiles(FirebaseFirestore firestore) async {
    print('🚀 Iniciando Job de Inyección de 50 Perfiles Sintéticos (IMX-V01)...');

    List<Map<String, dynamic>> allProfiles = [];

    // 1. Alto Riesgo (IMX 0-30) - 10 perfiles
    for (int i = 0; i < 10; i++) {
      allProfiles.add(_generateProfile(
        categoryName: 'Alto Riesgo',
        gender: _randomTarget(['male', 'female']),
        height: _randomDouble(160, 180),
        waistRatioTarget: _randomDouble(0.65, 0.75), // Mal ratio
        neck: _randomDouble(40, 48),
        fastingHours: _randomInt(0, 10),
        energy: _randomInt(1, 3),
        nutrition: _randomInt(1, 4),
        exercise: _randomInt(1, 3),
        sleepHours: _randomDouble(4, 5.5),
      ));
    }

    // 2. Deterioro (IMX 30-50) - 10 perfiles
    for (int i = 0; i < 10; i++) {
      allProfiles.add(_generateProfile(
        categoryName: 'Deterioro',
        gender: _randomTarget(['male', 'female']),
        height: _randomDouble(160, 180),
        waistRatioTarget: _randomDouble(0.55, 0.64),
        neck: _randomDouble(35, 42),
        fastingHours: _randomInt(10, 12),
        energy: _randomInt(3, 5),
        nutrition: _randomInt(3, 5),
        exercise: _randomInt(2, 4),
        sleepHours: _randomDouble(5.5, 6.5),
      ));
    }

    // 3. Recuperación (IMX 50-65) - 10 perfiles
    for (int i = 0; i < 10; i++) {
      allProfiles.add(_generateProfile(
        categoryName: 'Recuperación',
        gender: _randomTarget(['male', 'female']),
        height: _randomDouble(160, 180),
        waistRatioTarget: _randomDouble(0.50, 0.54),
        neck: _randomDouble(33, 40),
        fastingHours: _randomInt(12, 14),
        energy: _randomInt(5, 7),
        nutrition: _randomInt(5, 7),
        exercise: _randomInt(4, 6),
        sleepHours: _randomDouble(6.5, 7.5),
      ));
    }

    // 4. Saludable (IMX 65-80) - 10 perfiles
    for (int i = 0; i < 10; i++) {
      allProfiles.add(_generateProfile(
        categoryName: 'Saludable',
        gender: _randomTarget(['male', 'female']),
        height: _randomDouble(160, 180),
        waistRatioTarget: _randomDouble(0.45, 0.49),
        neck: _randomDouble(31, 38),
        fastingHours: _randomInt(14, 16),
        energy: _randomInt(7, 9),
        nutrition: _randomInt(7, 8),
        exercise: _randomInt(6, 8),
        sleepHours: _randomDouble(7.5, 8.5),
      ));
    }

    // 5. Óptimo (IMX 80-100) - 10 perfiles
    for (int i = 0; i < 10; i++) {
      allProfiles.add(_generateProfile(
        categoryName: 'Óptimo',
        gender: _randomTarget(['male', 'female']),
        height: _randomDouble(160, 180),
        waistRatioTarget: _randomDouble(0.40, 0.44), // Ratios de atleta
        neck: _randomDouble(30, 36),
        fastingHours: _randomInt(16, 20),
        energy: _randomInt(9, 10),
        nutrition: _randomInt(9, 10),
        exercise: _randomInt(8, 10),
        sleepHours: _randomDouble(8.0, 9.0),
      ));
    }

    print('📊 Inyectando en Firestore a la colección "pruebas"...');
    
    final batch = firestore.batch();
    final collection = firestore.collection('pruebas');

    for (var profile in allProfiles) {
      batch.set(collection.doc(), profile);
    }

    await batch.commit();

    print('✅ 50 Perfiles inyectados exitosamente.');

    // Print summary stats
    print('\n📈 --- RESUMEN ESTADÍSTICO DE DISTRIBUCIÓN ---');
    final Map<String, int> distribution = {
      'Riesgo Severo (0-30)': 0,
      'Deterioro (30-50)': 0,
      'Recuperación (50-65)': 0,
      'Saludable (65-80)': 0,
      'Óptimo (80-100)': 0,
    };

    for (var p in allProfiles) {
      double score = p['quiz']['imxScore'];
      if (score < 30) distribution['Riesgo Severo (0-30)'] = distribution['Riesgo Severo (0-30)']! + 1;
      else if (score < 50) distribution['Deterioro (30-50)'] = distribution['Deterioro (30-50)']! + 1;
      else if (score < 65) distribution['Recuperación (50-65)'] = distribution['Recuperación (50-65)']! + 1;
      else if (score < 80) distribution['Saludable (65-80)'] = distribution['Saludable (65-80)']! + 1;
      else distribution['Óptimo (80-100)'] = distribution['Óptimo (80-100)']! + 1;
    }

    distribution.forEach((key, count) {
      print('$key: $count perfiles');
    });
    print('-----------------------------------------');
  }

  static Map<String, dynamic> _generateProfile({
    required String categoryName,
    required String gender,
    required double height,
    required double waistRatioTarget,
    required double neck,
    required int fastingHours,
    required int energy,
    required int nutrition,
    required int exercise,
    required double sleepHours,
  }) {
    double waist = height * waistRatioTarget;
    // Cadera dependiente del genero y cintura aprox
    double hip = gender == 'female' ? waist * _randomDouble(1.1, 1.3) : waist * _randomDouble(0.9, 1.1);

    // Calcular SCORES CAPA POR CAPA
    final b = ImxCalculator.calculateBodyScore(waist, height, hip, neck);
    final m = ImxCalculator.calculateMetabolicScore(fastingHours.toDouble(), energy);
    final h = ImxCalculator.calculateLifestyleScore(nutrition.toDouble(), exercise.toDouble(), sleepHours);
    
    // SCORE FINAL
    final totalIMX = ImxCalculator.calculateTotalIMX(
      waistCm: waist,
      heightCm: height,
      hipCm: hip,
      neckCm: neck,
      avgFastingHours: fastingHours.toDouble(),
      energyLevel1To10: energy,
      nutritionAdherenceScore: nutrition.toDouble(),
      exerciseAdherenceScore: exercise.toDouble(),
      avgSleepHours: sleepHours,
    );
    
    // Computar clasificación manual para el JSON
    String classificationStr;
    if (totalIMX <= 30) classificationStr = 'highRisk';
    else if (totalIMX <= 50) classificationStr = 'warning';
    else if (totalIMX <= 70) classificationStr = 'moderate';
    else if (totalIMX <= 85) classificationStr = 'good';
    else classificationStr = 'optimal';

    return {
      'metadata': {
        'test_id': 'IMX_STRESS_TEST_001',
        'timestamp': FieldValue.serverTimestamp(),
        'version': 'IMX-V01',
        'target_category': categoryName,
      },
      'quiz': {
        // Entradas
        'inputs': {
          'gender': gender,
          'height': height,
          'waist': waist,
          'hip': hip,
          'neck': neck,
          'fastingHours': fastingHours,
          'energyLevel': energy,
          'nutritionScore': nutrition,
          'exerciseScore': exercise,
          'sleepHours': sleepHours,
        },
        // Resultados Motores
        'bodyScore_B': b,
        'metabolicScore_M': m,
        'lifestyleScore_H': h,
        'imxScore': totalIMX,
        'classification': classificationStr,
      },
      'content': {},
      'app_integration': {
        'email_sintetico': 'test_${_random.nextInt(999999)}@elena-imx.com',
        'nombre_sintetico': 'Paciente $categoryName ${_random.nextInt(999)}',
      }
    };
  }

  static double _randomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  static int _randomInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  static String _randomTarget(List<String> options) {
    return options[_random.nextInt(options.length)];
  }
}
