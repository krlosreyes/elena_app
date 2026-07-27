# Tests en rojo — triaje y resolución, 27-jul-2026

La primera corrida de `flutter test` tras las correcciones de la auditoría dio
**1984 pasados · 2 saltados · 10 fallidos**. La segunda, **1987 · 2 · 7**.

De esos fallos, **1 era mío y 9 eran anteriores a esta sesión**. Todos están
resueltos. Ninguno se "arregló" ajustando el número esperado hasta que pasara:
en cada caso hubo que decidir primero si fallaba el test o fallaba el código.

El hallazgo de fondo importa más que los diez fallos:

> **La suite llevaba semanas en rojo y nadie lo sabía.** Los dos tests de
> reconciliación de racha rompieron el 18-jul. Los tres de `protocolChanged`,
> el 20-jul. Los de "Para ti", el 17-jul. Si `flutter test` corriera en algún
> gate, cada uno de esos cambios habría sido bloqueado el mismo día.
>
> Peor: la auditoría de esta mañana publicó "59,5 % de cobertura" leyendo un
> `lcov.info` del 22-jul que referencia rutas de archivos que ya no existen.
> Una cobertura obsoleta no es información neutra: es confianza infundada.

---

## Veredicto por caso

### Fallaba el CÓDIGO (1)

| Test | Diagnóstico | Corrección |
|---|---|---|
| `bootstrap_error_app_test` — "un onRetry que falla no rompe la pantalla" | **Mío.** Escribí el test esperando que la excepción escapara al framework. Al verlo fallar quedó claro que el comportamiento correcto es el contrario: `BootstrapErrorApp` es la última pantalla que le queda al usuario y no puede tumbarse porque el reintento falle. | `catch` en `_pulsar` que absorbe el fallo y vuelve a habilitar el botón. El error no se pierde: `_bootstrapProtegido` ya lo registra en Crashlytics. Test reescrito para afirmar que la pantalla sobrevive y admite un segundo intento. |

### Fallaba el TEST — fixture caducado (2)

| Test | Diagnóstico | Corrección |
|---|---|---|
| `streak_engine_reconcile_test` — "sin reconciliar… racha 2 → 1" | Fechas fijas (`2026-07-17`) y llamada a `computeCurrentStreakWithFreezes` **sin `asOf`**, así que el motor caía en `DateTime.now()`. El parámetro `asOf` se añadió el 18-jul; los tests se escribieron el 17-jul y nunca se actualizaron. Desde el 18-jul la cadena se cortaba en el primer día ausente y devolvían 0. | `asOf` explícito. Verificado por simulación: con `asOf` dan 1 y 2; sin él, 0 y 0 — que es exactamente lo que reportaba la suite. |
| `streak_engine_reconcile_test` — "con reconciliar… se mantiene en 2" | Idéntico. | Idéntico. |

### Fallaba el TEST — afirmaba una función retirada a propósito (3)

Los tres asertaban `ClosureReason.protocolChanged`, trigger **eliminado el
20-jul por decisión de producto** (ver la nota extensa en
`metabolic_cycle_resolver.dart`): cerraba el día en curso apenas el usuario
tocaba "cambiar protocolo" en Configuración, aunque estuviera en plena ventana
de alimentación sin ninguna intención de ayunar.

Ninguno se borró. Los tres se **invirtieron** para blindar la regla nueva, que
vale más que la función que se quitó:

| Test | Ahora afirma |
|---|---|
| `metabolic_cycle_resolver_test` — "protocolChanged dispara…" | `cambiar de protocolo NO cierra el ciclo en curso` → `shouldClose` devuelve `null` |
| `metabolic_cycle_resolver_test` — "Prioridad: protocolChanged gana…" | Con protocolo cambiado **y** ayuno nuevo, el motivo es `manualNextFasting`: el cambio de configuración no secuestra el motivo de cierre |
| `metabolic_cycle_service_test` — "Cierre por protocolChanged…" | No hay cierre ni apertura, y el ciclo abierto **conserva su protocolo** (`16:8`): el `20:4` aplica al ciclo siguiente |

### Fallaba el TEST — afirmaba un detalle del framework (1)

| Test | Diagnóstico | Corrección |
|---|---|---|
| `glucose_chart_test` — "sin lecturas… sin CustomPaint" | Afirmaba `find.byType(CustomPaint)` con `findsNothing`. El widget hace lo correcto (muestra el mensaje vacío, no pinta), pero Flutter monta `CustomPaint` propios dentro de `Scaffold`/`Material`. El test estaba acoplado al árbol interno del framework, no al widget bajo prueba. | Finder por predicado sobre el painter concreto del gráfico. De paso, los otros tres tests del archivo pasan de `findsWidgets` a `findsOneWidget`, que es lo que de verdad quieren decir. |

### Fallaba el TEST — texto retirado del widget (2)

| Test | Diagnóstico | Corrección |
|---|---|---|
| `for_you_section_test` ×2 | Buscaban `'Para ti'`. El 17-jul la sección se rebautizó "Aprende con Elena" y el título pasó al contenedor; `ForYouSection` dejó de renderizar cabecera propia. | Se retiran los dos asserts de cabecera. El resto —que valida el contenido real del feed— se conserva intacto. |

---

## Lo más interesante que apareció

**El archivo `streak_engine_fasting_history_test.dart` se contradecía a sí
mismo.** Dos tests del mismo grupo afirmaban reglas opuestas para fixtures de la
misma forma (ayuno que empieza una noche y cierra a la mañana siguiente):

- `CASO REAL: 2 ciclos el mismo día` esperaba **16.0** → atribución por `endTime`
- `atribuye por startTime, no por endTime` esperaba **0.0** → atribución por `startTime`

No podían pasar los dos. La pregunta no era cuál test arreglar sino **cuál regla
es la correcta**, y esa la responde la Constitución del Día Metabólico §1: el
ciclo lo abre el tap "Iniciar ayuno" (`startedAt`), así que un ayuno pertenece
al día en que **empezó**. La implementación ya seguía esa regla.

Se corrigió el fixture del `CASO REAL` a dos ciclos que empiezan y cierran el
mismo día —que es literalmente lo que dice su título— con lo que conserva
intacta la regresión que vino a proteger (que un ayuno cerrado se siga leyendo
del historial aunque haya otro ciclo activo encima) sin contradecir la
constitución.

---

## Lo que hay que hacer para que no vuelva a pasar

Arreglar diez tests vale menos que impedir que se pudran otros diez:

1. **`flutter test` en el gate de commit** (o al menos en el de push). Es la
   única medida que convierte "la suite está roja" en información inmediata en
   vez de en un descubrimiento arqueológico.
2. **Regenerar `coverage/lcov.info` en cada corrida de `validate.sh`** y fallar
   si tiene más de 7 días.
3. **Ningún test con fecha fija sin reloj inyectado.** El motor de racha ya
   acepta `asOf`; los dos tests que rompieron lo habrían sobrevivido si lo
   hubieran usado desde el principio. Vale como regla de revisión en PR.
4. **Al retirar una función, invertir su test en el mismo PR.** Los tres de
   `protocolChanged` estuvieron siete días afirmando un comportamiento que el
   producto había decidido eliminar.
