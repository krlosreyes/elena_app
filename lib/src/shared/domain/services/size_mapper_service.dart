import 'dart:math' as math;

class ProbabilisticMeasurement {
  final double mean;
  final double std;
  ProbabilisticMeasurement(this.mean, this.std);

  double sample() {
    final rand = math.Random();
    double u1 = rand.nextDouble();
    double u2 = rand.nextDouble();
    if (u1 == 0) u1 = 0.0001;
    double z0 = math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
    return mean + (z0 * std);
  }
}

class SizeMapperService {
  /// Inferencia Cruzada para Onboarding (Pantalón dicta Cintura | Camisa dicta Cuello)
  static Map<String, double> inferCrossed({
    required int pantSize, 
    required String shirtSize, 
    required String gender
  }) {
    final bool isMale = gender.toUpperCase() == 'M';
    
    // Cintura: Talla + 2 pulgadas convertido a cm
    double waist = (pantSize + 2) * 2.54;
    
    // Cuello: Basado en tallas de camisa estándar
    double neck;
    if (isMale) {
      switch (shirtSize.toUpperCase()) {
        case "S":  neck = 37.5; break;
        case "M":  neck = 39.5; break;
        case "L":  neck = 42.0; break;
        case "XL": neck = 44.5; break;
        default:   neck = 39.5;
      }
    } else {
      switch (shirtSize.toUpperCase()) {
        case "S":  neck = 32.5; break;
        case "M":  neck = 34.5; break;
        case "L":  neck = 36.5; break;
        default:   neck = 34.5;
      }
    }

    return {"waist": waist, "neck": neck};
  }

  static ProbabilisticMeasurement inferWaist(int pantSize) => 
      ProbabilisticMeasurement((pantSize + 2) * 2.54, 5.0);

  static ProbabilisticMeasurement inferNeck(String shirtSize, String gender) {
    bool isMale = gender.toUpperCase() == 'M';
    double mean = isMale 
      ? (shirtSize == "S" ? 37.5 : shirtSize == "L" ? 42.0 : 39.5)
      : (shirtSize == "S" ? 32.5 : shirtSize == "L" ? 36.5 : 34.5);
    return ProbabilisticMeasurement(mean, 1.5);
  }

  static double calculateBodyFat({
    required double waist, 
    required double neck, 
    required double height, 
    required String gender
  }) {
    if (waist <= neck || height <= 0) return 20.0;
    if (gender.toUpperCase() == 'M') {
      return 495 / (1.0324 - 0.19077 * (math.log(waist - neck) / math.ln10) + 0.15456 * (math.log(height) / math.ln10)) - 450;
    } else {
      return 495 / (1.29579 - 0.35004 * (math.log(waist + 15 - neck) / math.ln10) + 0.22100 * (math.log(height) / math.ln10)) - 450;
    }
  }
}