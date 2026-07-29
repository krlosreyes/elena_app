// Cómo se le explica el Día Metabólico al usuario (2026-07-28).
//
// POR QUÉ EXISTE ESTE ARCHIVO
// ---------------------------
// "Día Metabólico" aparecía en 10 sitios de la UI —el aviso de comidas,
// el cierre de ciclo, el histórico, el Score del Día— y no existía una
// sola pantalla que dijera qué es. El usuario lo leía en mayúsculas como
// si ya lo supiera.
//
// El copy vive aquí, en el dominio y junto al motor, y NO en el widget:
// es la misma decisión que `FastingEligibility.efectoSobreElAyuno` y que
// `_timelineFor` derivado de `FastingPhase`. Si las reglas cambian, el
// texto está a la vista de quien las toca en vez de quedarse
// desactualizado en una pantalla que nadie relaciona.
//
// LA TRAMPA DE "¿A QUÉ HORA?"
// ---------------------------
// La pregunta natural del usuario es "¿a qué hora empieza y termina mi
// día metabólico?" y NO tiene respuesta en horas. METABOLIC_DAY_
// CONSTITUTION §1 lo prohíbe expresamente:
//
//   "El día metabólico es un ciclo definido EXCLUSIVAMENTE por eventos
//    del usuario. CERO referencia al reloj del calendario."
//
// Así que la respuesta honesta es que no hay hora: empieza cuando tocas
// "Iniciar ayuno" y termina cuando empiezas el siguiente. Decir una hora
// concreta sería contradecir al motor.
//
// LA EXCEPCIÓN QUE HAY QUE DECIR
// ------------------------------
// Con protocolo 'Ninguno' el ciclo SÍ es calendárico y cierra a las
// 23:59 (`MetabolicCycleResolver.calendarFallbackCloseAt`). Son dos
// comportamientos distintos bajo el mismo nombre, y callarlo deja al
// usuario sin entender lo que ve.
//
// Importa más de lo que parece por quién cae ahí: el cribado médico
// (`FastingEligibility.assess`) recorta a 'Ninguno' el protocolo de
// embarazo y trastorno alimentario. Las personas con más motivo para no
// confundirse son justo las que están en el modo que no explicábamos.

import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart';

/// Frase núcleo. Es la única definición y se repite igual en onboarding,
/// en la hoja explicativa y en cualquier sitio que la necesite — dos
/// redacciones distintas de la misma regla es como empiezan las
/// incoherencias.
const String kMetabolicDayCoreDefinition =
    'Tu día metabólico no empieza a medianoche: empieza cuando inicias '
    'tu ayuno y termina cuando empiezas el siguiente.';

/// El porqué, en una línea. Sin esto la definición suena a capricho.
const String kMetabolicDayRationale =
    'Tu cuerpo no mira el reloj: responde a cuándo comes y cuándo '
    'descansas. Por eso trasnochar un día no te rompe la racha — lo que '
    'cuenta es tu ciclo, no la medianoche.';

const String kMetabolicDayStartTitle = 'Cuándo empieza';
const String kMetabolicDayStartBody =
    'Cuando tocas «Iniciar ayuno». Ese es el único gesto que abre tu día '
    'metabólico — ni despertarte, ni la medianoche, ni abrir la app.';

const String kMetabolicDayEndTitle = 'Cuándo termina';
const String kMetabolicDayEndBody =
    'Cuando empiezas tu siguiente ayuno. Cerrar el día y abrir el '
    'siguiente son el mismo gesto.';

/// Qué cierra el ciclo cuando el usuario no lo cierra.
///
/// **Se deriva de las constantes del resolver.** Escribir "3 horas" a
/// mano sería crear un segundo lugar donde vive el mismo número: el día
/// que alguien cambie `kFallbackAfterWindowGrace`, el texto seguiría
/// diciendo lo viejo y nadie se enteraría. Ya nos pasó con la
/// notificación de autofagia a las 16 h.
String get kMetabolicDayAutoCloseBody {
  final horasVentana = kFallbackAfterWindowGrace.inHours;
  final horasTope = kAbsoluteCycleLimit.inHours;
  return 'Si se te pasa, lo cerramos por ti: cuando llevas $horasVentana h '
      'sin comer tras tu ventana, cuando detectamos que dormiste, o a las '
      '$horasTope h como tope de seguridad. Siempre te decimos cuál fue.';
}

const String kMetabolicDayAutoCloseTitle = 'Si se te olvida cerrarlo';

/// El modo calendárico, para quien no tiene protocolo de ayuno.
const String kMetabolicDayCalendarTitle = 'Si no tienes protocolo de ayuno';
const String kMetabolicDayCalendarBody =
    'Sin ayuno no hay ciclo que anclar, así que tu día va con el '
    'calendario y cierra a medianoche. En cuanto elijas un protocolo, tu '
    'día pasa a marcarlo tu ayuno.';

/// True si a este usuario le aplica el modo calendárico. Wrapper fino
/// sobre el resolver para que la UI no tenga que conocer el literal
/// `'Ninguno'`.
bool usaDiaCalendario(String fastingProtocol) =>
    MetabolicCycleResolver.useCalendarFallback(fastingProtocol);
