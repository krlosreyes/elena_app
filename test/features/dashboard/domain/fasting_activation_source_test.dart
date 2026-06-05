// SPEC-183 (2026-06-05): tests del campo `activationSource` en
// FastingState. Verifican el contrato mínimo:
//   - default es `none`
//   - copyWith preserva o actualiza el source
//   - los 3 valores del enum están definidos
//
// La cobertura del comportamiento end-to-end (bootstrap NO crea ciclo,
// userInitiated SÍ crea ciclo) se valida manualmente en iPhone/Chrome
// porque el evaluator es un Provider side-effect montado en el árbol
// del Dashboard que requiere harness completo.

import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-183 — FastingActivationSource', () {
    test('los 3 valores del enum están definidos', () {
      expect(FastingActivationSource.values.length, 3);
      expect(FastingActivationSource.values, contains(FastingActivationSource.none));
      expect(FastingActivationSource.values,
          contains(FastingActivationSource.bootstrap));
      expect(FastingActivationSource.values,
          contains(FastingActivationSource.userInitiated));
    });

    test('FastingState inicial: activationSource es none', () {
      final state = FastingState.initial();
      expect(state.activationSource, FastingActivationSource.none);
    });

    test('copyWith sin pasar activationSource preserva el valor previo', () {
      final state = FastingState(
        activationSource: FastingActivationSource.bootstrap,
      );
      final copy = state.copyWith(isActive: true);
      expect(copy.activationSource, FastingActivationSource.bootstrap);
    });

    test('copyWith con activationSource lo actualiza', () {
      final state = FastingState(
        activationSource: FastingActivationSource.bootstrap,
      );
      final copy = state.copyWith(
        activationSource: FastingActivationSource.userInitiated,
      );
      expect(copy.activationSource, FastingActivationSource.userInitiated);
    });

    test('cambio de none a userInitiated por user tap', () {
      // Caso de uso: usuario presiona "iniciar ayuno" → startFastingManual
      // setea activationSource=userInitiated. Solo este caso debe
      // disparar creación de ciclo metabólico (cf. SPEC-183 §3.4).
      final initial = FastingState.initial();
      expect(initial.activationSource, FastingActivationSource.none);
      final after = initial.copyWith(
        isActive: true,
        activationSource: FastingActivationSource.userInitiated,
      );
      expect(after.isActive, isTrue);
      expect(after.activationSource, FastingActivationSource.userInitiated);
    });

    test('cambio de none a bootstrap por restore de Firestore', () {
      // Caso de uso: app arranca y el listener al
      // lastFastingIntervalProvider restaura un interval persistido.
      // Setea activationSource=bootstrap → el evaluator NO debe crear
      // ciclo nuevo (cf. SPEC-183 §3.3).
      final initial = FastingState.initial();
      final after = initial.copyWith(
        isActive: true,
        activationSource: FastingActivationSource.bootstrap,
      );
      expect(after.isActive, isTrue);
      expect(after.activationSource, FastingActivationSource.bootstrap);
    });
  });
}
