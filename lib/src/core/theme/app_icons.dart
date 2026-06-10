// Sistema de íconos de ElenaApp — FUENTE ÚNICA DE VERDAD.
//
// Propuesta de UI (2026-06-09): un solo set, Material Symbols *Rounded*,
// para matar los emojis y garantizar que el MISMO pilar/métrica use el MISMO
// ícono en todas las pantallas (Home, Análisis, Perfil, Objetivos, Progreso).
// Los valores de pilares ya coinciden con la fila del Home (referencia).
//
// Reglas de uso:
//  - Tamaño: 20px en filas, 18px en chips, 16px inline. Máx 24 decorativo.
//  - Color: blanco ~70% en neutro, acento (teal/pilar) en activo. Nunca
//    multicolor, nunca emoji.

import 'package:flutter/material.dart';

class AppIcons {
  AppIcons._();

  // ── 5 pilares (canónicos, iguales a la fila del Home) ─────────────────────
  static const IconData ayuno = Icons.timer_rounded;
  static const IconData sueno = Icons.nightlight_round;
  static const IconData hidratacion = Icons.water_drop_rounded;
  static const IconData ejercicio = Icons.fitness_center_rounded;
  static const IconData nutricion = Icons.restaurant_rounded;

  // ── Resultados / métricas ─────────────────────────────────────────────────
  /// IMR: un índice/score → medidor con aguja (decisión de marca).
  static const IconData imr = Icons.speed_rounded;
  static const IconData peso = Icons.monitor_weight_rounded;
  static const IconData composicion = Icons.accessibility_new_rounded;
  static const IconData grasa = Icons.local_fire_department_rounded;
  static const IconData masaMagra = Icons.accessibility_new_rounded;
  static const IconData cinturaEstatura = Icons.straighten_rounded;

  // ── Secciones / estados ───────────────────────────────────────────────────
  static const IconData objetivos = Icons.flag_rounded;
  static const IconData analisis = Icons.insights_rounded;
  static const IconData bloqueado = Icons.lock_outline_rounded;
  static const IconData tendenciaSube = Icons.trending_up_rounded;
  static const IconData tendenciaBaja = Icons.trending_down_rounded;
  static const IconData tendenciaPlana = Icons.trending_flat_rounded;

  // ── Tiers del IMR (estado; el color comunica, el ícono acompaña) ──────────
  static const IconData tierExcelente = Icons.emoji_events_rounded;
  static const IconData tierBien = Icons.check_circle_rounded;
  static const IconData tierAtencion = Icons.bolt_rounded;
  static const IconData tierBajo = Icons.adjust_rounded;
}
