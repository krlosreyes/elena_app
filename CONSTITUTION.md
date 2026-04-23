# CONSTITUTION.md
Sistema: Elena App
Versión: 1.0 (Post-SDD Baseline)

---

# 1. PROPÓSITO

Este documento define las reglas obligatorias que gobiernan todo el sistema.

Estas reglas no son sugerencias.

Si el código las viola:
→ el código está mal

---

# 2. PRINCIPIO FUNDAMENTAL

La SPEC es la fuente de verdad.

- El código es un artefacto derivado
- No se escribe código sin spec
- No se modifica código sin plan

---

# 3. ARQUITECTURA OBLIGATORIA

Toda funcionalidad debe seguir esta estructura:

feature/
 ├── domain/
 ├── application/
 ├── data/
 └── presentation/

---

## 3.1 DOMAIN

Responsabilidad:

- reglas de negocio
- modelos
- invariantes

Reglas:

- ❌ No depende de Flutter
- ❌ No depende de Firestore
- ✔ Contiene validaciones
- ✔ Define contratos

---

## 3.2 APPLICATION

Responsabilidad:

- casos de uso
- orquestación
- providers (Riverpod)

Reglas:

- ❌ No contiene lógica de UI
- ❌ No accede directamente a Firestore
- ✔ Usa repositorios

---

## 3.3 DATA

Responsabilidad:

- acceso a Firestore
- implementación de repositorios

Reglas:

- ✔ Traduce entre modelos y persistencia
- ✔ Maneja errores externos

---

## 3.4 PRESENTATION

Responsabilidad:

- UI

Reglas:

- ❌ No contiene lógica de negocio
- ❌ No valida datos complejos
- ✔ Solo consume providers

---

# 4. REGLAS DE ESTADO (RIVERPOD)

- Todo estado global debe estar en providers
- No usar setState para lógica de negocio
- Los providers representan el estado del sistema

---

# 5. PERSISTENCIA (FIRESTORE)

Reglas:

- Todo acceso pasa por repositorios
- No escribir directamente desde UI
- Validar datos antes de persistir

---

# 6. VALIDACIÓN

- Toda validación pertenece al dominio
- No duplicar validaciones en UI
- Los modelos deben ser consistentes por diseño

---

# 7. CORE SYSTEM (ENGINE + ORCHESTRATOR)

Ubicación:
src/core/

Reglas:

- Representa el sistema metabólico
- No puede ser modificado sin spec
- Toda lógica debe ser explícita

---

# 8. PROHIBICIONES

- ❌ Código sin spec
- ❌ Acceso directo a datos desde UI
- ❌ Lógica en widgets
- ❌ Validaciones duplicadas
- ❌ Cambios sin trazabilidad

---

# 9. TESTING (FASE POSTERIOR)

- Los tests se generan desde la spec
- No se escriben tests sin spec

---

# 10. TRAZABILIDAD

Todo cambio debe:

- referenciar una spec
- tener un plan
- ser verificable

---

# 11. REGLA FINAL

Si el sistema se vuelve difícil de entender:

→ la spec está incompleta  
→ no el código