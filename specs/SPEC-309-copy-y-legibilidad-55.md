# SPEC-309 — Copy coherente con el sitio y legibilidad para 55+

Estado: IMPLEMENTED (27-nov-2026) · Versión: Elena 1.0.1

## Decisiones de Carlos (27-nov)
1. Quitar de la UI las etiquetas Tipo A/E y Pasivo/Excitado.
2. Quitar la numeración "1 · / 3 ·" de las tarjetas de Progreso (faltaba la 2).
3. Mejorar la lectura de textos grises pequeños: la audiencia es mayoritariamente de 55+.

## Legibilidad (hallazgos)
- ~1.100 textos con tamaño fijo ≤ 12,5 pt (34 de 9 pt, 8 de 8 pt).
- ~280 textos en blanco con opacidad 0,25–0,6: contraste de 2,7:1 en el peor caso (WCAG AA pide 4,5:1).
- `textMuted` #64748B: 4,2:1 sobre el fondo.

## Cambios de legibilidad
- `MinSizeTextScaler`: tamaño mínimo renderizado de 12,5 pt, respetando el tamaño de texto del sistema (Dynamic Type). Íconos sin cambio.
- Textos con opacidad < 0,65 → 0,7 y `white24/38/54/60` → `white70` (solo dentro de `TextStyle`): 343 textos en 127 archivos.
- `textSecondary` #B8C4D4 (10,9:1) y `textMuted` #94A3B8 (7,9:1).
- Tipografía base: 11 → 12,5 y 12 → 13.
- Botón "Registrar mis medidas" con alto mínimo (no fijo) para que no se corte.

Referencias: WCAG 2.2 criterio 1.4.3; NIA/NLM "Making Your Website Senior Friendly"; Apple HIG (tamaño mínimo 11 pt).

## Copy
- Tipo A/E → "verduras y proteína" / "almidones y azúcares". Pasivo/Excitado → "ritmo tranquilo" / "ritmo acelerado".
- Autofagia: sin hora exacta en personas; se retiran "autofagia activa" a las 12–16 h, "IGF-1", "renovación mitocondrial", "cambio de combustible", "es algo que hemos visto".
- Ohsumi: "Mecanismos de la autofagia (Nobel de Medicina)", no "autofagia y ayuno".
- IMR y edad metabólica se nombran por separado.
- Voseo retirado (Conectá, preferís, Tocá, podés, tenés, etc.). Nombre visible: "Elena".
- Calendario y textos del sistema en español (delegados de localización).
