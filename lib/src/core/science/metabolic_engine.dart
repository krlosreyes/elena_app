import 'package:flutter/material.dart';

enum CircadianPhase {
  morningActivation, testosteronePeak, cognitivePeak, afternoonDip, 
  neuromotorWindow, thermalDecompression, melatoninRise, digestiveLock;
  
  // 🛡️ Aliases para compatibilidad con código antiguo (Notificaciones/Analytics)
  static CircadianPhase get morningSensitivity => morningActivation;
}

enum MetabolicZone {
  postAbsorption, glycogenDepletion, fatBurning, deepKetosis, autophagy, survivalMode
}

extension MetabolicZoneTheme on MetabolicZone {
  Color get color {
    switch (this) {
      case MetabolicZone.postAbsorption: return const Color(0xFF9E9E9E);
      case MetabolicZone.glycogenDepletion: return const Color(0xFFFFD600);
      case MetabolicZone.fatBurning: return const Color(0xFFFF9800);
      case MetabolicZone.deepKetosis: return const Color(0xFFF44336);
      case MetabolicZone.autophagy: return const Color(0xFF9C27B0);
      case MetabolicZone.survivalMode: return const Color(0xFFB71C1C);
    }
  }

  double? get nextZoneThresholdHours {
    switch (this) {
      case MetabolicZone.postAbsorption: return 12.0;
      case MetabolicZone.glycogenDepletion: return 18.0;
      case MetabolicZone.fatBurning: return 24.0;
      case MetabolicZone.deepKetosis: return 48.0;
      case MetabolicZone.autophagy: return 72.0;
      default: return null;
    }
  }

  bool get isCritical => this == MetabolicZone.survivalMode;
}

abstract class MetabolicEngine {
  /// Calcula la zona metabólica activa según las horas de ayuno transcurridas.
  static MetabolicZone calculateZone(Duration fastingTime) {
    final h = fastingTime.inMinutes / 60.0;
    if (h >= 72) return MetabolicZone.survivalMode;
    if (h >= 48) return MetabolicZone.autophagy;
    if (h >= 24) return MetabolicZone.deepKetosis;
    if (h >= 18) return MetabolicZone.fatBurning;
    if (h >= 12) return MetabolicZone.glycogenDepletion;
    return MetabolicZone.postAbsorption;
  }

  static CircadianPhase getCurrentCircadianPhase({DateTime? now}) {
    final time = now ?? DateTime.now();
    final mins = (time.hour * 60) + time.minute;

    if (mins >= 1350 || mins < 360) return CircadianPhase.digestiveLock;
    if (mins < 540) return CircadianPhase.morningActivation;
    if (mins < 600) return CircadianPhase.testosteronePeak;
    if (mins < 780) return CircadianPhase.cognitivePeak;
    if (mins < 870) return CircadianPhase.afternoonDip;
    if (mins < 1080) return CircadianPhase.neuromotorWindow;
    if (mins < 1260) return CircadianPhase.thermalDecompression;
    return CircadianPhase.melatoninRise;
  }
}