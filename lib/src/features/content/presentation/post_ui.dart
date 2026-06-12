// SPEC-205 inc3: helpers visuales del feed (color/emoji por pilar).

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/content/domain/post.dart';

class PostUi {
  PostUi._();

  /// Color de acento por pilar (coherente con PillarConstants.colors).
  static Color pillarColor(PillarTag pillar) {
    switch (pillar) {
      case PillarTag.ayuno:
        return const Color(0xFF10B981); // esmeralda
      case PillarTag.ejercicio:
        return const Color(0xFF2DD4BF); // teal
      case PillarTag.nutricion:
        return const Color(0xFFFB923C); // naranja
      case PillarTag.sueno:
      case PillarTag.hidratacion:
        return const Color(0xFF818CF8); // índigo (soporte)
      case PillarTag.general:
        return const Color(0xFFF59E0B); // ámbar
    }
  }

  static String pillarEmoji(PillarTag pillar) {
    switch (pillar) {
      case PillarTag.ayuno:
        return '⏱️';
      case PillarTag.ejercicio:
        return '💪';
      case PillarTag.nutricion:
        return '🥦';
      case PillarTag.sueno:
        return '🌙';
      case PillarTag.hidratacion:
        return '💧';
      case PillarTag.general:
        return '⚡';
    }
  }
}
