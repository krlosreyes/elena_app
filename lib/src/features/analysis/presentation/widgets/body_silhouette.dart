// SPEC-168.4.4 (2026-06-03) — v2: silueta humana como SVG asset por zona.
//
// La primera versión usaba un CustomPainter abstracto que se veía
// rígido. Carlos compartió 3 SVG ilustrativos por nivel de composición
// (saludable / promedio / alto riesgo) — esos se ven naturales y
// comunican mejor el estado.
//
// Mapeo zona ACSM → asset:
//   Esencial / Atlético / Fitness → assets/silhouettes/body_healthy.svg
//   Promedio                      → assets/silhouettes/body_average.svg
//   Alto                          → assets/silhouettes/body_high.svg

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:elena_app/src/features/analysis/domain/body_zone.dart';

class BodySilhouette extends StatelessWidget {
  const BodySilhouette({
    super.key,
    required this.bodyFatPct,
    required this.isMale,
  });

  /// % grasa corporal actual del usuario. Null = no medido.
  final double? bodyFatPct;

  /// Reservado para futuras variantes femeninas. Hoy las 3 siluetas
  /// son neutras / masculinas y se reusan para ambos géneros.
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    final zone = bodyZoneFor(bodyFatPct, isMale);
    if (zone == null) {
      return _buildPlaceholder();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          height: 180,
          child: SvgPicture.asset(
            _assetForZone(zone),
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        _ZoneBadge(zone: zone),
        const SizedBox(height: 4),
        Text(
          '${bodyFatPct!.toStringAsFixed(1)}% grasa · rangos ACSM '
          '${isMale ? '♂' : '♀'}',
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
    // Sin BF: mostramos la silueta "healthy" en gris neutral con un
    // mensaje invitando a registrar la métrica.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: 0.35,
          child: SizedBox(
            width: 110,
            height: 180,
            child: SvgPicture.asset(
              'assets/silhouettes/body_healthy.svg',
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.55),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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

  /// Mapeo zona ACSM → archivo SVG. 5 zonas, 3 estados visuales.
  String _assetForZone(BodyZone zone) {
    switch (zone) {
      case BodyZone.esencial:
      case BodyZone.atletico:
      case BodyZone.fitness:
        return 'assets/silhouettes/body_healthy.svg';
      case BodyZone.promedio:
        return 'assets/silhouettes/body_average.svg';
      case BodyZone.alto:
        return 'assets/silhouettes/body_high.svg';
    }
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
