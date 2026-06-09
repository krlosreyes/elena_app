// Fix anillo de ayuno (2026-06-09) — tests de `FastingState.progressPercentage`.
//
// Bug: al cerrar un ayuno ANTES del target, el anillo del pilar caía a 0%
// (porque `isActive` pasa a false y `completedToday` solo se marca cuando
// se alcanza el target). Comportamiento correcto: mostrar el % logrado.
// `closedProgressToday` preserva esa fracción.

import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingState.progressPercentage', () {
    test('ayuno activo → % en vivo sobre el target', () {
      final s = FastingState(
        fastingProtocol: '16:8',
        isActive: true,
        duration: const Duration(hours: 8), // 8/16 = 0.5
      );
      expect(s.progressPercentage, closeTo(0.5, 1e-9));
    });

    test('cierre TEMPRANO conserva el % logrado (no cae a 0)', () {
      // Cerró a 14h de un target de 16h → 0.875.
      final s = FastingState(
        fastingProtocol: '16:8',
        isActive: false,
        closedProgressToday: 0.875,
      );
      expect(s.progressPercentage, closeTo(0.875, 1e-9));
    });

    test('completedToday tiene prioridad → 100%', () {
      final s = FastingState(
        fastingProtocol: '16:8',
        isActive: false,
        completedToday: true,
        closedProgressToday: 0.9, // ignorado: completedToday manda
      );
      expect(s.progressPercentage, 1.0);
    });

    test('sin ayuno hoy (closedProgressToday null) → 0', () {
      final s = FastingState(fastingProtocol: '16:8', isActive: false);
      expect(s.progressPercentage, 0.0);
    });

    test('closedProgressToday se clampa a [0,1]', () {
      final over = FastingState(
        fastingProtocol: '16:8',
        isActive: false,
        closedProgressToday: 1.4,
      );
      expect(over.progressPercentage, 1.0);
    });

    test('ayuno activo ignora closedProgressToday (usa el vivo)', () {
      // Aunque haya un % de cierre previo en el state, si vuelve a haber
      // ayuno activo el getter usa la duración en curso.
      final s = FastingState(
        fastingProtocol: '16:8',
        isActive: true,
        duration: const Duration(hours: 4), // 0.25
        closedProgressToday: 0.9,
      );
      expect(s.progressPercentage, closeTo(0.25, 1e-9));
    });
  });
}
