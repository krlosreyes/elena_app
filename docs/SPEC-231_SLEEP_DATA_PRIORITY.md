# SPEC-231: Prioridad de Datos de Sueño — HealthKit > Manual > Onboarding

**Status**: IMPLEMENTED  
**Prioridad**: HIGH — afecta experiencia diaria del usuario cada mañana  
**Fecha**: 2026-06-18  
**Origen**: Carlos reporta "dato de sueño hardcodeado" al abrir la app en la mañana.

---

## 1. Contexto

Al abrir la app por la mañana, el dato de sueño mostrado parecía "hardcodeado": siempre las mismas horas genéricas (22:30→7:00) en lugar de datos reales del usuario. La causa raíz es doble:

1. **SleepInputSheet** pre-cargaba valores fijos `22:30/7:00` en lugar de leer el perfil circadiano del onboarding.
2. **confirmManualWakeUp** tenía un guard de duplicados que solo comparaba el `docId` exacto (`sleep_YYYY-MM-DD`), pero los logs de HealthKit usan `hk_sleep_*` y Samsung Health usa `sh_sleep_*` — nunca matcheaba, creando un duplicado manual que sobrescribía datos precisos del wearable.

---

## 2. Cadena de Prioridad de Datos

La arquitectura ya soporta la cadena correcta. El pipeline es:

```
HealthKit / Health Connect (wearable)
    ↓  escribe a Firestore: sleep_history/{hk_sleep_*}
    ↓
SleepNotifier.watchLatest() ← Firestore stream
    ↓  state.lastLog = log más reciente por wokeUp
    ↓
currentCycleSleepProvider ← filtra por ciclo/día
    ↓
Dashboard muestra datos reales del wearable
```

Si NO hay datos de wearable:
1. Se muestra overlay "¿Ya despertaste?" → `confirmManualWakeUp` infiere `fellAsleep` desde `profile.sleepTime` (correcto, ya existía)
2. O el usuario abre `SleepInputSheet` → ahora pre-carga `profile.sleepTime/wakeUpTime` en vez de 22:30/7:00

---

## 3. Bugs Corregidos

### BUG-231-A: SleepInputSheet defaults hardcodeados (MEDIO)

**Archivo**: `sleep_input_sheet.dart`, línea 61  
**Categoría**: UX / DATA-QUALITY

**Mecanismo**: Cuando `initial == null` (crear nuevo registro), el sheet inicializaba:
```dart
_bedtime = const TimeOfDay(hour: 22, minute: 30);
_wakeTime = const TimeOfDay(hour: 7, minute: 0);
```

Esto ignoraba completamente el perfil circadiano del usuario configurado en onboarding. Un usuario que duerme a las 23:30 y despierta a las 6:00 veía 22:30→7:00 y tenía que ajustar manualmente cada vez.

**Fix**: Leer `currentUserStreamProvider` → `profile.sleepTime/wakeUpTime`. Fallback a 22:30/7:00 solo si el perfil no está disponible.

---

### BUG-231-B: Guard de duplicados no reconoce logs de HealthKit (ALTO)

**Archivo**: `sleep_notifier.dart`, línea 226  
**Categoría**: DATA-OVERWRITE

**Mecanismo**: `confirmManualWakeUp` verificaba:
```dart
if (state.lastLog?.id == docId) { return; } // no sobreescribir
```

Pero `docId` es `sleep_YYYY-MM-DD` (formato de atribución manual) mientras que HealthKit produce `hk_sleep_<uuid>` y Samsung Health produce `sh_sleep_<timestamp>`. El guard NUNCA matcheaba contra datos de wearable → se creaba un segundo log manual con horas inferidas que sobrescribía el dato preciso del wearable en Firestore.

**Fix**: Guard ampliado que verifica:
- OR 1: `lastLog.id == docId` (mismo ID de atribución)
- OR 2: `lastLog.wokeUp` está en el mismo día calendárico que `now` (cualquier fuente)

Si cualquiera es true, no se crea un duplicado.

---

## 4. Archivos Modificados

| Archivo | Bug | Cambio |
|---------|-----|--------|
| `sleep_input_sheet.dart` | A | Lee CircadianProfile para defaults en vez de 22:30/7:00 |
| `sleep_notifier.dart` | B | Guard ampliado: docId OR sameCalendarDay |

---

## 5. Invariantes Post-Fix

1. **SleepInputSheet** siempre pre-carga las horas del perfil circadiano del usuario
2. **confirmManualWakeUp** nunca sobrescribe un log de HealthKit/Samsung Health del mismo día
3. **Cadena de prioridad**: wearable > manual > onboarding-fallback — garantizada por el diseño del pipeline Firestore
4. **`watchLatest`** siempre retorna el log más reciente por `wokeUp` — si HealthKit sincronizó después del manual, el stream emite el nuevo y `state.lastLog` se actualiza automáticamente
