// Módulo "Tu Glucosa" — tests de GlucoseClassifier (propuesta §12.1,
// umbrales ADA). Cubre ayunas/postprandial2h con casos límite exactos
// (los bordes 70/100/125/140/199 son los números clínicamente
// relevantes, no arbitrarios) + contextos sin umbral + R9
// (warrantsMedicalAdviceNote / isOutsidePlausibleRange).

import 'package:elena_app/src/features/glucose/domain/glucose_classification.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlucoseClassifier.classify — ayunas', () {
    test('< 70 → bajo', () {
      expect(
        GlucoseClassifier.classify(69, GlucoseReadingContext.ayunas),
        GlucoseClassification.bajo,
      );
    });

    test('70..99 → en rango (borde inferior y superior)', () {
      expect(
        GlucoseClassifier.classify(70, GlucoseReadingContext.ayunas),
        GlucoseClassification.enRango,
      );
      expect(
        GlucoseClassifier.classify(99, GlucoseReadingContext.ayunas),
        GlucoseClassification.enRango,
      );
    });

    test('100..125 → elevado (borde inferior y superior)', () {
      expect(
        GlucoseClassifier.classify(100, GlucoseReadingContext.ayunas),
        GlucoseClassification.elevado,
      );
      expect(
        GlucoseClassifier.classify(125, GlucoseReadingContext.ayunas),
        GlucoseClassification.elevado,
      );
    });

    test('> 125 → alto', () {
      expect(
        GlucoseClassifier.classify(126, GlucoseReadingContext.ayunas),
        GlucoseClassification.alto,
      );
    });
  });

  group('GlucoseClassifier.classify — postprandial2h', () {
    test('< 70 → bajo', () {
      expect(
        GlucoseClassifier.classify(65, GlucoseReadingContext.postprandial2h),
        GlucoseClassification.bajo,
      );
    });

    test('70..139 → en rango', () {
      expect(
        GlucoseClassifier.classify(139, GlucoseReadingContext.postprandial2h),
        GlucoseClassification.enRango,
      );
    });

    test('140..199 → elevado (borde inferior y superior)', () {
      expect(
        GlucoseClassifier.classify(140, GlucoseReadingContext.postprandial2h),
        GlucoseClassification.elevado,
      );
      expect(
        GlucoseClassifier.classify(199, GlucoseReadingContext.postprandial2h),
        GlucoseClassification.elevado,
      );
    });

    test('> 199 → alto', () {
      expect(
        GlucoseClassifier.classify(200, GlucoseReadingContext.postprandial2h),
        GlucoseClassification.alto,
      );
    });
  });

  group('GlucoseClassifier.classify — sin umbral ADA', () {
    test('antesDeDormir/antesDeComer/postprandial1h/otro → sinUmbral', () {
      for (final ctx in [
        GlucoseReadingContext.antesDeDormir,
        GlucoseReadingContext.antesDeComer,
        GlucoseReadingContext.postprandial1h,
        GlucoseReadingContext.otro,
      ]) {
        expect(
          GlucoseClassifier.classify(110, ctx),
          GlucoseClassification.sinUmbral,
          reason: '$ctx no tiene umbral ADA propio — nunca se inventa uno',
        );
      }
    });
  });

  group('GlucoseClassifier.warrantsMedicalAdviceNote (R9)', () {
    test('< 70 amerita nota', () {
      expect(GlucoseClassifier.warrantsMedicalAdviceNote(69), isTrue);
    });
    test('> 250 amerita nota', () {
      expect(GlucoseClassifier.warrantsMedicalAdviceNote(251), isTrue);
    });
    test('rango medio no amerita nota', () {
      expect(GlucoseClassifier.warrantsMedicalAdviceNote(110), isFalse);
    });
  });

  group('GlucoseClassifier.isOutsidePlausibleRange (R9)', () {
    test('dentro de 40-400 → plausible', () {
      expect(GlucoseClassifier.isOutsidePlausibleRange(40), isFalse);
      expect(GlucoseClassifier.isOutsidePlausibleRange(400), isFalse);
    });
    test('fuera de 40-400 → no plausible', () {
      expect(GlucoseClassifier.isOutsidePlausibleRange(39), isTrue);
      expect(GlucoseClassifier.isOutsidePlausibleRange(401), isTrue);
    });
  });
}
