// TEST-08 (auditoría pre-producción 2026-07-11).
//
// EngagementService.calculateEngagement no tenía ningún test. Cubre el
// período de gracia (< kGracePeriodDays días con actividad → neutro) y los
// 4 umbrales de adherencia semanal que clasifican el nivel de engagement.

import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EngagementService.calculateEngagement — período de gracia', () {
    test('menos de kGracePeriodDays días con actividad → neutro/Calibrando', () {
      final state = EngagementService.calculateEngagement(0.95, historyDays: 2);
      expect(state.level, EngagementLevel.neutro);
      expect(state.status, 'Calibrando');
      expect(state.adherence, 0);
    });

    test('0 días de historial → neutro incluso con adherencia alta', () {
      final state = EngagementService.calculateEngagement(1.0, historyDays: 0);
      expect(state.level, EngagementLevel.neutro);
    });
  });

  group('EngagementService.calculateEngagement — umbrales de adherencia', () {
    test('adherencia >= 0.85 con historial suficiente → excelente', () {
      final state = EngagementService.calculateEngagement(0.9,
          historyDays: EngagementService.kGracePeriodDays);
      expect(state.level, EngagementLevel.excelente);
      expect(state.status, 'Excelente');
      expect(state.adherence, 0.9);
    });

    test('exactamente 0.85 → excelente (umbral inclusivo)', () {
      final state = EngagementService.calculateEngagement(0.85,
          historyDays: EngagementService.kGracePeriodDays);
      expect(state.level, EngagementLevel.excelente);
    });

    test('adherencia entre 0.70 y 0.85 → bueno', () {
      final state = EngagementService.calculateEngagement(0.75,
          historyDays: EngagementService.kGracePeriodDays);
      expect(state.level, EngagementLevel.bueno);
      expect(state.status, 'Bueno');
    });

    test('adherencia entre 0.50 y 0.70 → regular', () {
      final state = EngagementService.calculateEngagement(0.55,
          historyDays: EngagementService.kGracePeriodDays);
      expect(state.level, EngagementLevel.regular);
      expect(state.status, 'Regular');
    });

    test('adherencia por debajo de 0.50 → crítico', () {
      final state = EngagementService.calculateEngagement(0.2,
          historyDays: EngagementService.kGracePeriodDays);
      expect(state.level, EngagementLevel.critico);
      expect(state.status, 'Crítico');
    });
  });
}
