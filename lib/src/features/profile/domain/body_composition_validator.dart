/// SPEC-25: Validador de Composición Corporal
/// Asegura que los datos sean realistas y coherentes

class BodyCompositionValidator {
  /// Valida todos los datos de composición corporal
  static ValidationResult validate({
    required double weight,
    required double height,
    required double bodyFatPercentage,
    required double? waistCircumference,
    required double? neckCircumference,
  }) {
    final errors = <String>[];

    // Validar peso
    if (weight < 30 || weight > 250) {
      errors.add('Peso debe estar entre 30 y 250 kg');
    }

    // Validar altura
    if (height < 140 || height > 220) {
      errors.add('Estatura debe estar entre 140 y 220 cm');
    }

    // Validar % grasa corporal
    if (bodyFatPercentage < 2 || bodyFatPercentage > 60) {
      errors.add('% grasa corporal debe estar entre 2% y 60%');
    }

    // Validar cintura si se proporciona
    if (waistCircumference != null) {
      if (waistCircumference < 50 || waistCircumference > 150) {
        errors.add('Cintura debe estar entre 50 y 150 cm');
      }

      // WHTR (Waist-to-Height Ratio) debe ser realista
      final whtr = waistCircumference / height;
      if (whtr < 0.3 || whtr > 0.8) {
        errors.add('Proporción cintura-estatura no realista (estima entre 0.3-0.8)');
      }
    }

    // Validar cuello si se proporciona
    if (neckCircumference != null) {
      if (neckCircumference < 20 || neckCircumference > 50) {
        errors.add('Circunferencia de cuello debe estar entre 20 y 50 cm');
      }
    }

    // Validar coherencia: masa magra debe ser positiva y realista
    final leanMass = weight * (1 - bodyFatPercentage / 100);
    if (leanMass < 20 || leanMass > weight * 0.95) {
      errors.add('Los datos de peso y % grasa no son coherentes');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Detecta si el cambio es significativo (>10%)
  static bool isSignificantChange({
    required double oldValue,
    required double newValue,
    double threshold = 0.10, // 10%
  }) {
    final change = (newValue - oldValue).abs();
    final percentChange = (change / oldValue).abs();
    return percentChange > threshold;
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });

  String get errorMessage => errors.join('\n• ');
}
