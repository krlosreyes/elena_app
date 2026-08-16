// Propuesta "Avances / Tu camino" (15-jul): metadata visual de categoría
// (ícono + color + nombre) extraída de badge_gallery.dart a un lugar
// compartido — la necesitan tanto la galería (badge_gallery.dart) como la
// nueva línea de tiempo (tu_camino_timeline.dart), y antes vivía duplicada
// solo en la galería. Una sola fuente de verdad evita que ambas pantallas
// terminen mostrando colores/íconos distintos para la misma categoría.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/badges/domain/badge_definition.dart';

class BadgeCategoryMeta {
  final String displayName;
  final IconData icon;
  final Color color;
  const BadgeCategoryMeta(this.displayName, this.icon, this.color);
}

const Map<String, BadgeCategoryMeta> kBadgeCategoryMeta = {
  BadgeCategory.racha: BadgeCategoryMeta(
      'Racha', Icons.local_fire_department_rounded, Color(0xFFF97316)),
  BadgeCategory.ayuno: BadgeCategoryMeta(
      'Ayuno consciente', Icons.hourglass_bottom_rounded, Color(0xFF22D3EE)),
  BadgeCategory.sueno: BadgeCategoryMeta(
      'Sueño reparador', Icons.nightlight_round, Color(0xFF818CF8)),
  BadgeCategory.hidratacion: BadgeCategoryMeta(
      'Hidratación constante', Icons.water_drop_rounded, Colors.blueAccent),
  BadgeCategory.ejercicio: BadgeCategoryMeta(
      'Movimiento', Icons.directions_run_rounded, Color(0xFF34D399)),
  BadgeCategory.nutricion: BadgeCategoryMeta(
      'Nutrición consciente', Icons.restaurant_rounded, Color(0xFFF59E0B)),
  BadgeCategory.imr: BadgeCategoryMeta(
      'Transformación', Icons.trending_up_rounded, Color(0xFF10B981)),
  BadgeCategory.checkin: BadgeCategoryMeta(
      'Autoconocimiento', Icons.monitor_weight_outlined, Color(0xFFEC4899)),
  BadgeCategory.resiliencia:
      BadgeCategoryMeta('Resiliencia', Icons.spa_rounded, Color(0xFF14B8A6)),
  BadgeCategory.bienvenida: BadgeCategoryMeta(
      'Bienvenida', Icons.emoji_events_rounded, Color(0xFFFBBF24)),
  // SPEC-264 agregó la categoría `retos` a BadgeCategory.all y al catálogo,
  // pero nunca aquí — la galería hacía `kBadgeCategoryMeta[retos]!` y reventaba
  // esa celda (Null check operator used on a null value). Se añade su metadata.
  BadgeCategory.retos: BadgeCategoryMeta(
      'Retos', Icons.military_tech_rounded, Color(0xFF2DD4BF)),
};

/// Metadata visual segura por categoría: si una categoría no está en el mapa
/// (p. ej. una nueva que se agregó a `BadgeCategory.all` sin metadata), devuelve
/// un default genérico en vez de reventar. Así la galería nunca vuelve a caerse
/// por una categoría sin registrar.
const BadgeCategoryMeta kBadgeCategoryMetaFallback =
    BadgeCategoryMeta('Logros', Icons.emoji_events_rounded, Color(0xFF94A3B8));

BadgeCategoryMeta badgeCategoryMetaFor(String category) =>
    kBadgeCategoryMeta[category] ?? kBadgeCategoryMetaFallback;
