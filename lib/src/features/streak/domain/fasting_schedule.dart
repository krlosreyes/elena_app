// SPEC-257 §3.1: días de ayuno programados para el nivel Novato.
//
// Grounding: Suárez recomienda 2-3 días de ayuno/semana como esquema
// canónico de entrada (esquema "2-5"), con la opción de subir a 3 sin
// pedir supervisión adicional. Fung valida el TRF diario como punto de
// entrada legítimo, pero su nivel 2 de intensidad (24h) es intrínsecamente
// de baja frecuencia. Ninguno de los dos respalda exigir ayuno los 7 días
// a alguien que recién empieza — por eso este archivo solo aplica a los
// protocolos de entrada (12:12, 14:10). 16:8 en adelante sigue siendo
// ventana diaria sin cambios, tal como ambos autores la tratan.
//
// Marco normativo: specs/SPEC-257-clasificacion-protocolo-ayuno.md §3.1.

import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

class FastingSchedule {
  FastingSchedule._();

  /// Protocolos de nivel Novato (SPEC-257 Eje B) — únicos donde aplica
  /// la frecuencia semanal reducida en vez de ventana diaria.
  static const List<String> novatoTierProtocols = ['12:12', '14:10'];

  static bool isNovatoTier(String protocol) =>
      novatoTierProtocols.contains(protocol);

  /// Default de días/semana cuando el usuario no fijó
  /// `GoalType.fastingDaysPerWeek` (hoy huérfano — SPEC-257 lo conecta
  /// por primera vez a algo real).
  static const int defaultDaysPerWeek = 3;

  /// Rango que SPEC-257 §3.1 respalda sin pedir supervisión adicional
  /// (Suárez: "2-5", con opción de subir a 3; más de eso, deriva a un
  /// profesional).
  static const int minDaysPerWeek = 2;
  static const int maxDaysPerWeek = 4;

  /// Días de la semana (`DateTime.weekday`, 1=lunes..7=domingo) asignados
  /// por defecto para cada N — siempre no consecutivos. Para N=2 usa el
  /// propio ejemplo de Suárez en la fuente primaria (martes/viernes).
  static List<int> defaultWeekdays(int daysPerWeek) {
    final n = daysPerWeek.clamp(minDaysPerWeek, maxDaysPerWeek);
    switch (n) {
      case 2:
        return const [DateTime.tuesday, DateTime.friday];
      case 4:
        return const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.thursday,
          DateTime.friday,
        ];
      case 3:
      default:
        return const [DateTime.monday, DateTime.wednesday, DateTime.friday];
    }
  }

  /// Días/semana efectivo: el goal activo del usuario
  /// (`GoalType.fastingDaysPerWeek`) recortado a
  /// [minDaysPerWeek, maxDaysPerWeek]; si no hay goal activo,
  /// [defaultDaysPerWeek].
  ///
  /// SPEC-257 LIMPIEZA: el slider genérico de "Mis objetivos"
  /// (`UserGoal.sliderMin/sliderMax`) acepta 1-7 para este `GoalType` —
  /// es compartido entre los 7 tipos de goal y no conoce el tope
  /// específico de nivel Novato. Antes, un valor fuera de [2,4] se
  /// IGNORABA del todo y caía al default (3) sin decírselo al usuario:
  /// alguien que fijara "5 días/semana" en Perfil vería "5" persistido
  /// pero el anillo se comportaba como si hubiera puesto 3. Recortar
  /// (`clamp`) en vez de descartar respeta la intención del usuario
  /// dentro del rango que la fuente primaria respalda sin supervisión
  /// adicional (Suárez "2-5, opción de subir a 3").
  static int effectiveDaysPerWeek(GoalsMap goals) {
    final g = goals[GoalType.fastingDaysPerWeek];
    if (g == null || !g.isActive) return defaultDaysPerWeek;
    final v = g.targetValue.round();
    return v.clamp(minDaysPerWeek, maxDaysPerWeek);
  }

  /// true si [date] es un día de descanso PROGRAMADO. Solo tiene efecto
  /// para protocolos de nivel Novato — para cualquier otro protocolo
  /// (16:8 en adelante) siempre devuelve false, porque esos siguen siendo
  /// ventana diaria sin días de descanso.
  static bool isRestDay({
    required DateTime date,
    required String protocol,
    required GoalsMap goals,
  }) {
    if (!isNovatoTier(protocol)) return false;
    final n = effectiveDaysPerWeek(goals);
    final scheduled = defaultWeekdays(n);
    return !scheduled.contains(date.weekday);
  }
}
