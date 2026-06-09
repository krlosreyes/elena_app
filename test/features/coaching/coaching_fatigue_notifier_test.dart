// SPEC-194 RF-2.5 — tests del store anti-fatiga persistente.

import 'package:elena_app/src/features/coaching/application/coaching_fatigue_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  CoachingFatigueNotifier make(DateTime Function() clock) =>
      CoachingFatigueNotifier(prefs, clock: clock);

  test('recordShown agrega el id a shownToday (penaliza repetir hoy)', () {
    final n = make(() => DateTime(2026, 6, 9, 10));
    n.recordShown('a');
    expect(n.state.shownTodayActionIds, contains('a'));
    // Repetir el mismo id no duplica ni rompe.
    n.recordShown('a');
    expect(n.state.shownTodayActionIds.length, 1);
  });

  test('recordCompleted resetea la racha de ignorada a 0', () {
    var day = DateTime(2026, 6, 9, 10);
    final n = make(() => day);
    n.recordShown('a');
    // Pasa a otro día sin completar → ignored['a'] = 1.
    day = DateTime(2026, 6, 10, 10);
    n.recordShown('b'); // dispara rollover
    expect(n.state.ignoredStreakByActionId['a'], 1);
    // Ahora se completa 'a' → racha vuelve a 0 (se elimina).
    n.recordCompleted('a');
    expect(n.state.ignoredStreakByActionId.containsKey('a'), isFalse);
  });

  test('rollover de día incrementa ignored de lo mostrado-no-completado', () {
    var day = DateTime(2026, 6, 9, 10);
    final n = make(() => day);
    n.recordShown('a');
    n.recordShown('b');
    n.recordCompleted('b'); // b sí se completó hoy

    day = DateTime(2026, 6, 10, 8);
    n.recordShown('c'); // dispara rollover del día anterior

    // 'a' se mostró y no se completó → ignored=1; 'b' completado → no penaliza.
    expect(n.state.ignoredStreakByActionId['a'], 1);
    expect(n.state.ignoredStreakByActionId.containsKey('b'), isFalse);
    // Los sets de "hoy" se limpiaron y arrancan con 'c'.
    expect(n.state.shownTodayActionIds, {'c'});
  });

  test('ignored se acumula por días distintos ignorados consecutivos', () {
    var day = DateTime(2026, 6, 9, 10);
    final n = make(() => day);
    n.recordShown('a');
    day = DateTime(2026, 6, 10, 10);
    n.recordShown('a'); // rollover: ignored=1, y se vuelve a mostrar
    day = DateTime(2026, 6, 11, 10);
    n.recordShown('a'); // rollover: ignored=2
    expect(n.state.ignoredStreakByActionId['a'], 2);
  });

  test('persiste y rehidrata el estado entre instancias', () {
    final day = DateTime(2026, 6, 9, 10);
    final n1 = make(() => day);
    n1.recordShown('a');
    n1.recordShown('b');

    // Nueva instancia, mismo prefs, mismo día → conserva shownToday.
    final n2 = make(() => day);
    expect(n2.state.shownTodayActionIds, containsAll(['a', 'b']));
  });

  test('primer arranque (sin datos previos) no inventa ignorados', () {
    final n = make(() => DateTime(2026, 6, 9, 10));
    expect(n.state.ignoredStreakByActionId, isEmpty);
    expect(n.state.shownTodayActionIds, isEmpty);
  });
}
