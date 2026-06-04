// SPEC-168.4.4 (2026-06-03): silueta humana abstracta como contexto
// clínico en el detalle de Composición corporal.
//
// El color de la silueta refleja la zona ACSM del usuario (Atlético,
// Fitness, Promedio, Alto). Debajo, badge con el nombre de la zona.
//
// Pintada con CustomPainter — sin assets ni packages adicionales.
// Mantenemos un look minimal/simbólico, no anatómico.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/body_zone.dart';

class BodySilhouette extends StatelessWidget {
  const BodySilhouette({
    super.key,
    required this.bodyFatPct,
    required this.isMale,
  });

  /// % grasa corporal actual del usuario. Null = no medido.
  final double? bodyFatPct;

  /// True si el usuario es hombre (rangos ACSM masculinos). False = mujer.
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    final zone = bodyZoneFor(bodyFatPct, isMale);
    if (zone == null) {
      return _buildPlaceholder();
    }
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 170,
          child: CustomPaint(
            painter: _SilhouettePainter(
              color: zone.color,
              isMale: isMale,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ZoneBadge(zone: zone),
        const SizedBox(height: 4),
        Text(
          isMale
              ? '${bodyFatPct!.toStringAsFixed(1)}% grasa · rangos ACSM ♂'
              : '${bodyFatPct!.toStringAsFixed(1)}% grasa · rangos ACSM ♀',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 170,
          child: CustomPaint(
            painter: _SilhouettePainter(
              color: Colors.white.withValues(alpha: 0.18),
              isMale: isMale,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Registrá tu % de grasa para ver tu zona ACSM.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  const _ZoneBadge({required this.zone});
  final BodyZone zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: zone.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: zone.color.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Text(
        'Zona ${zone.label}',
        style: TextStyle(
          color: zone.color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter({required this.color, required this.isMale});

  final Color color;
  final bool isMale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Cabeza (círculo).
    final headRadius = w * 0.13;
    final headCenter = Offset(cx, h * 0.10);
    canvas.drawCircle(headCenter, headRadius, fillPaint);

    // Cuello (rectángulo corto entre cabeza y torso).
    final neckRect = Rect.fromLTWH(
      cx - w * 0.04,
      h * 0.18,
      w * 0.08,
      h * 0.04,
    );
    canvas.drawRect(neckRect, fillPaint);

    // Torso (trapezoide ancho arriba — hombros — que se estrecha en
    // la cintura). Hombres más anchos en hombros; mujeres más en caderas.
    final shoulderHalf =
        isMale ? w * 0.32 : w * 0.27; // hombros
    final waistHalf =
        isMale ? w * 0.18 : w * 0.16; // cintura

    final torsoPath = Path()
      ..moveTo(cx - shoulderHalf, h * 0.22) // hombro izq
      ..lineTo(cx + shoulderHalf, h * 0.22) // hombro der
      ..quadraticBezierTo(
        cx + shoulderHalf * 0.85,
        h * 0.38,
        cx + waistHalf,
        h * 0.48, // cintura der
      )
      ..lineTo(cx - waistHalf, h * 0.48) // cintura izq
      ..quadraticBezierTo(
        cx - shoulderHalf * 0.85,
        h * 0.38,
        cx - shoulderHalf,
        h * 0.22,
      )
      ..close();
    canvas.drawPath(torsoPath, fillPaint);

    // Caderas (rectángulo más ancho que la cintura; mujeres más anchas).
    final hipHalf = isMale ? w * 0.20 : w * 0.24;
    final hipPath = Path()
      ..moveTo(cx - waistHalf, h * 0.48)
      ..lineTo(cx + waistHalf, h * 0.48)
      ..lineTo(cx + hipHalf, h * 0.58)
      ..lineTo(cx - hipHalf, h * 0.58)
      ..close();
    canvas.drawPath(hipPath, fillPaint);

    // Piernas (2 rectángulos verticales con base redondeada).
    final legWidth = w * 0.16;
    final legGap = w * 0.04;
    final legTop = h * 0.58;
    final legBottom = h * 0.97;

    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - legGap / 2 - legWidth,
        legTop,
        cx - legGap / 2,
        legBottom,
      ),
      Radius.circular(w * 0.06),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx + legGap / 2,
        legTop,
        cx + legGap / 2 + legWidth,
        legBottom,
      ),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(leftLeg, fillPaint);
    canvas.drawRRect(rightLeg, fillPaint);

    // Brazos a los costados (rectángulos verticales delgados).
    final armWidth = w * 0.09;
    final armTop = h * 0.23;
    final armBottom = h * 0.55;
    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx - shoulderHalf - armWidth + 2,
        armTop,
        cx - shoulderHalf + 2,
        armBottom,
      ),
      Radius.circular(w * 0.05),
    );
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        cx + shoulderHalf - 2,
        armTop,
        cx + shoulderHalf + armWidth - 2,
        armBottom,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(leftArm, fillPaint);
    canvas.drawRRect(rightArm, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) =>
      old.color != color || old.isMale != isMale;
}
