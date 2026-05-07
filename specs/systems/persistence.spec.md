# persistence.spec.md
Sistema: Elena App
Versión: 1.0
Estado: ACTIVO

---

# 1. PROPÓSITO

Definir la estructura, reglas y contratos de persistencia del sistema.

Esta spec gobierna:

- qué datos existen
- cómo se almacenan
- cómo se validan
- cómo se reconstruye el sistema

---

# 2. PRINCIPIO FUNDAMENTAL

Firestore es la única fuente de verdad persistente.

El sistema se define como:

estado = f(eventos persistidos)

---

# 3. MODELO DE DATOS (AGREGADOS)

---

## 3.1 USER (Aggregate Root)

Representa la identidad del sistema.

### Campos:

- id: string
- gender: enum
- birthDate: date
- heightCm: number

### Invariantes:

- heightCm > 0
- birthDate < now

---

## 3.2 DAILY_RECORD (Aggregate Root — CRÍTICO)

Unidad de consistencia del sistema.

### Campos:

- date: YYYY-MM-DD
- userId: string

### Subcolecciones:

- meals → nutrition_log[]
- exercises → exercise_log[]
- hydration → hydration_log[]
- sleep → sleep_log[]
- biometrics → biometric_checkin[]

---

### Invariantes:

- Un único daily_record por usuario por día
- Todas las entradas deben pertenecer a ese día

---

## 3.3 NUTRITION_LOG (SPEC-63 + SPEC-64)

### Campos requeridos:

- id: string (uuid v4)
- timestamp: Timestamp (Firestore) — instante del registro
- label: enum {Desayuno, Almuerzo, Cena, Snack}
- withinCircadianWindow: bool — si la comida cayó dentro de [firstMealGoal, lastMealGoal]

### Campos opcionales (macronutrientes — SPEC-64):

- calories: number? (kcal) — null = "no se midió"; 0 = "midió y fue 0"
- protein: number? (gramos)
- carbs: number? (gramos)
- fat: number? (gramos)
- fiber: number? (gramos)
- glycemicIndex: number? (0-100)
- source: enum {userInput, catalog, estimated}

### Invariantes:

- id no vacío
- label dentro del set permitido
- timestamp ≤ now + 60s (tolerancia drift)
- Si presentes: calories ≥ 0, protein ≥ 0, carbs ≥ 0, fat ≥ 0, fiber ≥ 0
- Si presente: glycemicIndex en [0, 100]

### Notas de versión:

- Persistencia introducida en SPEC-63 (R1) en `users/{uid}/nutrition_history/{logId}`.
- Macros añadidos en SPEC-64 (R2). Logs pre-SPEC-64 leen los macros como null.
- SPEC-49 (R3) moverá la colección al aggregate `users/{uid}/daily_records/{date}/meals/{mealId}` sin cambiar el formato del documento.

---

## 3.4 EXERCISE_LOG

### Campos:

- id
- timestamp
- type
- durationMinutes
- caloriesBurned

### Invariantes:

- durationMinutes > 0

---

## 3.5 HYDRATION_LOG

### Campos:

- id
- timestamp
- ml

### Invariantes:

- ml > 0

---

## 3.6 SLEEP_LOG

### Campos:

- start
- end

### Invariantes:

- end > start

---

## 3.7 BIOMETRIC_CHECKIN

### Campos:

- timestamp
- weight
- bodyFatPercentage

### Invariantes:

- weight > 0

---

## 3.8 USER_GOAL

### Campos:

- targetWeight
- targetFatPercentage

---

# 4. ESTRUCTURA FIRESTORE

/users/{userId}

/users/{userId}/daily_records/{date}

/users/{userId}/daily_records/{date}/meals/{mealId}
/users/{userId}/daily_records/{date}/exercises/{exerciseId}
/users/{userId}/daily_records/{date}/hydration/{hydrationId}
/users/{userId}/daily_records/{date}/sleep/{sleepId}
/users/{userId}/daily_records/{date}/biometrics/{biometricId}

---

# 5. FLUJO DE ESCRITURA

INPUT → DTO  
→ Domain Entity (validación obligatoria)  
→ Repository  
→ Firestore  

---

## REGLAS:

- No se puede persistir sin validación
- No se puede escribir desde UI
- Todo pasa por repositorios

---

# 6. FLUJO DE LECTURA

Firestore → Repository → Domain → Engine → Provider → UI

---

# 7. RECONSTRUCCIÓN DEL ESTADO

El estado del sistema se reconstruye mediante:

- lectura de eventos
- procesamiento en engine

---

# 8. PROHIBICIONES

- ❌ escribir directamente a Firestore desde UI
- ❌ persistir estado derivado sin justificación
- ❌ duplicar datos en múltiples colecciones
- ❌ saltarse validación de dominio

---

# 9. ERRORES

Si un dato no cumple invariantes:

→ se rechaza  
→ no se persiste  

---

# 10. TESTABILIDAD

Cada entidad debe poder ser validada independientemente.

Cada flujo debe ser reproducible desde datos persistidos.

---

# 11. DEFINICIÓN DE CORRECTITUD

El sistema es correcto si:

- todos los datos cumplen invariantes
- el estado puede reconstruirse completamente
- no existen fuentes de verdad duplicadas