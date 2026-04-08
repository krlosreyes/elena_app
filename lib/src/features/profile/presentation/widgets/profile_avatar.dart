import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/biometric_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE AVATAR — SVG-based Body Profile with Interactive Hotspots & Muscle Glow
// METAMORFOSIS REAL PROTOCOL — Muscle Activation Visualization
// ─────────────────────────────────────────────────────────────────────────────

const Color _riskRed = Color(0xFFFF4444);
const Color _riskYellow = Color(0xFFFFD700);

class ProfileAvatar extends StatelessWidget {
  final UserModel user;
  final BiometricResult biometricResult;
  final Function(HotspotType) onHotspotTap;
  final double scale;
  final List<String> activeMuscles; // From last 24 hours workouts

  const ProfileAvatar({
    super.key,
    required this.user,
    required this.biometricResult,
    required this.onHotspotTap,
    this.scale = 1.35,
    this.activeMuscles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // SVG Avatar with Muscle Glow Effect
        _buildSVGAvatarWithGlow(),

        // Interactive Hotspots
        _buildHotspots(),
      ],
    );
  }

  /// Build SVG avatar with Muscle Glow effect
  /// Active muscles get bright neon green (#39FF14) with glow shadow
  Widget _buildSVGAvatarWithGlow() {
    final svgAsset = user.gender == Gender.male
        ? 'assets/images/hombre.svg'
        : 'assets/images/mujer.svg';

    // Base avatar with faint overlay
    final baseAvatar = SizedBox(
      width: 200 * scale,
      height: 400 * scale,
      child: SvgPicture.asset(
        svgAsset,
        colorFilter: ColorFilter.mode(
          AppTheme.primary.withValues(alpha: 0.2), // Elena Green @ 20% opacity base
          BlendMode.srcIn,
        ),
        fit: BoxFit.contain,
      ),
    );

    // If no active muscles, return base avatar
    if (activeMuscles.isEmpty) {
      return baseAvatar;
    }

    // Muscle glow overlay with active muscle highlighting
    return Stack(
      children: [
        // Base avatar
        baseAvatar,

        // Glow effect layer for active muscles
        _buildMuscleGlowOverlay(),
      ],
    );
  }

  /// Build overlay with muscle glow effects
  /// Maps muscle IDs to SVG paths and applies glow
  Widget _buildMuscleGlowOverlay() {
    return SizedBox(
      width: 200 * scale,
      height: 400 * scale,
      child: CustomPaint(
        painter: MuscleGlowPainter(
          activeMuscles: activeMuscles,
          scale: scale,
        ),
      ),
    );
  }

  /// Build interactive hotspots at specific body locations
  Widget _buildHotspots() {
    return SizedBox(
      width: 200 * scale,
      height: 400 * scale,
      child: Stack(
        children: [
          // Neck Hotspot
          _buildHotspot(
            type: HotspotType.neck,
            top: 35 * scale, // Top-left area, neck level
            left: 75 * scale,
            measurement: user.neckCircumferenceCm,
            riskLevel: biometricResult.imrRiskLevel,
          ),

          // Waist Hotspot
          _buildHotspot(
            type: HotspotType.waist,
            top: 150 * scale, // Middle area
            left: 70 * scale,
            measurement: user.waistCircumferenceCm,
            riskLevel: biometricResult.imrRiskLevel,
          ),

          // Hip Hotspot
          _buildHotspot(
            type: HotspotType.hip,
            top: 250 * scale, // Lower area
            left: 70 * scale,
            measurement: user.hipCircumferenceCm,
            riskLevel: biometricResult.imrRiskLevel,
          ),
        ],
      ),
    );
  }

  /// Individual hotspot widget
  Widget _buildHotspot({
    required HotspotType type,
    required double top,
    required double left,
    required double? measurement,
    required IMRRiskLevel riskLevel,
  }) {
    final color = _getHotspotColor(riskLevel);

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: () => onHotspotTap(type),
        child: Material(
          color: Colors.transparent,
          child: Tooltip(
            message: _getTooltipText(type, measurement),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.3), // Light background
                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add_circle,
                color: color,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get hotspot color based on IMR risk level
  Color _getHotspotColor(IMRRiskLevel riskLevel) {
    switch (riskLevel) {
      case IMRRiskLevel.red:
        return _riskRed;
      case IMRRiskLevel.yellow:
        return _riskYellow;
      case IMRRiskLevel.green:
        return AppTheme.primary;
    }
  }

  /// Generate tooltip text for hotspot
  String _getTooltipText(HotspotType type, double? measurement) {
    final measurementText = measurement != null
        ? '${measurement.toStringAsFixed(1)} cm'
        : 'Sin medida';

    switch (type) {
      case HotspotType.neck:
        return 'Cuello: $measurementText';
      case HotspotType.waist:
        return 'Cintura: $measurementText';
      case HotspotType.hip:
        return 'Cadera: $measurementText';
    }
  }
}

/// Enum for hotspot types
enum HotspotType { neck, waist, hip }

// ─────────────────────────────────────────────────────────────────────────────
// INTERACTIVE HOTSPOT BANNER — Material Banner with Delta Display
// ─────────────────────────────────────────────────────────────────────────────

/// Show interactive banner when hotspot is tapped
Future<void> showHotspotBanner(
  BuildContext context, {
  required HotspotType type,
  required double? currentMeasure,
  required double? targetMeasure,
}) {
  final delta = currentMeasure != null && targetMeasure != null
      ? (currentMeasure - targetMeasure).abs()
      : null;

  final deltaText = delta != null
      ? delta > 0
          ? '+${delta.toStringAsFixed(1)} cm'
          : '−${delta.toStringAsFixed(1)} cm'
      : 'Sin objetivo';

  final typeText = type == HotspotType.neck
      ? 'Cuello'
      : type == HotspotType.waist
          ? 'Cintura'
          : 'Cadera';

  ScaffoldMessenger.of(context).showMaterialBanner(
    MaterialBanner(
      content: Text(
        '$typeText: ${currentMeasure?.toStringAsFixed(1) ?? "N/A"} cm | Δ: $deltaText',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppTheme.primary.withValues(alpha: 0.8),
      actions: [
        TextButton(
          onPressed: () => ScaffoldMessenger.of(context).clearMaterialBanners(),
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    ),
  );

  final messenger = ScaffoldMessenger.of(context);
  return Future.delayed(const Duration(seconds: 4), () {
    messenger.clearMaterialBanners();
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MUSCLE GLOW PAINTER — Custom renderer for active muscle highlighting
// Applies glow effect to muscles worked in last 24 hours
// ─────────────────────────────────────────────────────────────────────────────

class MuscleGlowPainter extends CustomPainter {
  final List<String> activeMuscles;
  final double scale;

  MuscleGlowPainter({
    required this.activeMuscles,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Map muscle IDs to approximate SVG locations with glow radius
    final muscleGlowRegions = _getMuscleGlowRegions();

    for (final muscle in activeMuscles) {
      if (muscleGlowRegions.containsKey(muscle)) {
        final region = muscleGlowRegions[muscle]!;

        // Draw glow shadow effect
        _drawMuscleGlow(
          canvas,
          region['position'] as Offset,
          region['radius'] as double,
        );
      }
    }
  }

  /// Draw glow effect with shadow around active muscle
  void _drawMuscleGlow(Canvas canvas, Offset center, double radius) {
    // Outer glow shadow
    final glowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);

    canvas.drawCircle(center, radius + 8, glowPaint);

    // Bright inner glow
    final innerGlowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius, innerGlowPaint);
  }

  /// Map muscle IDs to approximate SVG locations on avatar
  /// These coordinates are normalized to a 200x400 canvas
  Map<String, Map<String, dynamic>> _getMuscleGlowRegions() {
    return {
      'quads': {
        'position': Offset(100 * scale, 240 * scale), // Upper leg
        'radius': 20.0 * scale,
      },
      'glutes': {
        'position': Offset(100 * scale, 200 * scale), // Buttocks area
        'radius': 18.0 * scale,
      },
      'hamstrings': {
        'position': Offset(100 * scale, 260 * scale), // Back of thigh
        'radius': 16.0 * scale,
      },
      'abs': {
        'position': Offset(100 * scale, 150 * scale), // Core
        'radius': 15.0 * scale,
      },
      'obliques': {
        'position': Offset(85 * scale, 160 * scale), // Side core
        'radius': 12.0 * scale,
      },
      'pecs': {
        'position': Offset(100 * scale, 90 * scale), // Chest
        'radius': 22.0 * scale,
      },
      'back': {
        'position': Offset(100 * scale, 110 * scale), // Upper back
        'radius': 25.0 * scale,
      },
      'shoulders': {
        'position': Offset(80 * scale, 70 * scale), // Shoulders
        'radius': 14.0 * scale,
      },
      'biceps': {
        'position': Offset(65 * scale, 120 * scale), // Upper arm
        'radius': 10.0 * scale,
      },
      'triceps': {
        'position': Offset(135 * scale, 130 * scale), // Back of arm
        'radius': 10.0 * scale,
      },
      'forearms': {
        'position': Offset(60 * scale, 140 * scale), // Lower arm
        'radius': 8.0 * scale,
      },
      'lats': {
        'position': Offset(75 * scale, 130 * scale), // Back wings
        'radius': 16.0 * scale,
      },
      'traps': {
        'position': Offset(95 * scale, 55 * scale), // Neck/upper back
        'radius': 12.0 * scale,
      },
      'calves': {
        'position': Offset(100 * scale, 320 * scale), // Lower leg
        'radius': 12.0 * scale,
      },
    };
  }

  @override
  bool shouldRepaint(MuscleGlowPainter oldDelegate) {
    return oldDelegate.activeMuscles != activeMuscles ||
        oldDelegate.scale != scale;
  }
}
