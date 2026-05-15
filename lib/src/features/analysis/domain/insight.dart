// SPEC-113: value object de un insight para mostrar en cards.
// El icono y color vienen como `IconData` y `Color` para que la
// presentación sea libre de mapear sin depender del tipo.

import 'package:flutter/material.dart' show Color, IconData;

class Insight {
  final IconData icon;
  final Color accent;
  final String title;
  final String description;

  const Insight({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
  });
}
