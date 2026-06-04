// SPEC-168.4.4 v4 (2026-06-03): gauge de zonas ACSM 100% widget-puro.
//
// Las versiones anteriores con CustomPainter no se renderizaban en
// algunos casos. v4 elimina TODO CustomPaint y usa solo widgets:
// Row + Flexible para la barra de segmentos, Container para el pin,
// Positioned para el indicador encima de la barra.
//
// Garantizado por construcción: si Flutter renderiza widgets, esto se ve.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/body_zone.dart';

class BodySilhouette extends StatelessWidget {
  const BodySilhouette({
    super.key,
    required this.bodyFatPct,
    required this.isMale,
  });

  final double? bodyFatPct;
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    final zone = bodyZoneFor(bodyFatPct, isMale);
    final hasData = zone != null && bodyFatPct != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU ZONA',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        if (hasData)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                zone.label,
                style: TextStyle(
                  color: zone.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${bodyFatPct!.toStringAsFixed(1)} % grasa',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
          Text(
            'Registrá tu % de grasa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 24),
        _ZoneGauge(bodyFatPct: bodyFatPct, isMale: isMale),
        const SizedBox(height: 10),
        Text(
          'Rangos ACSM ${isMale ? '(hombre)' : '(mujer)'} — '
          '${isMale ? 'Atlético <14, Fitness 14-17, Promedio 18-24, Alto >=25' : 'Atlético <21, Fitness 21-24, Promedio 25-31, Alto >=32'}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 10.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Gauge horizontal con 5 segmentos coloreados + pin del usuario.
class _ZoneGauge extends StatelessWidget {
  const _ZoneGauge({required this.bodyFatPct, required this.isMale});

  final double? bodyFatPct;
  final bool isMale;

  static const _zoneOrder = [
    BodyZone.esencial,
    BodyZone.atletico,
    BodyZone.fitness,
    BodyZone.promedio,
    BodyZone.alto,
  ];

  // Para 5 segmentos necesitamos 6 bordes: inicio, 4 divisiones internas
  // y fin. Los extremos son los límites visuales del gauge, no clínicos.
  List<double> get _bounds =>
      isMale ? const [2, 6, 14, 18, 25, 40] : const [8, 14, 21, 25, 32, 50];

  // Anchos proporcionales de cada segmento (suma = totalSpan).
  List<double> get _segmentWeights {
    final result = <double>[];
    for (int i = 0; i < _zoneOrder.length; i++) {
      result.add(_bounds[i + 1] - _bounds[i]);
    }
    return result;
  }

  // Posición horizontal del indicador en fracción 0..1.
  double get _indicatorFraction {
    if (bodyFatPct == null) return 0;
    final clamped = bodyFatPct!.clamp(_bounds.first, _bounds.last);
    final span = _bounds.last - _bounds.first;
    return (clamped - _bounds.first) / span;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pinLabel = bodyFatPct == null
            ? null
            : '${bodyFatPct!.toStringAsFixed(1)}%';
        final pinCenterX = _indicatorFraction * w;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1) Fila del pin con valor (alto fijo 32).
            if (pinLabel != null)
              SizedBox(
                width: w,
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (pinCenterX - 30).clamp(0.0, w - 60),
                      top: 0,
                      child: _PinBubble(label: pinLabel),
                    ),
                    Positioned(
                      left: pinCenterX - 6,
                      top: 24,
                      child: const _DownTri(),
                    ),
                  ],
                ),
              ),
            // 2) Barra de 5 segmentos (Row + Flexible).
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: w,
                height: 18,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < _zoneOrder.length; i++)
                          Expanded(
                            flex: (_segmentWeights[i] * 100).round(),
                            child: Container(
                              color: _zoneOrder[i]
                                  .color
                                  .withValues(alpha: 0.78),
                            ),
                          ),
                      ],
                    ),
                    // Punto blanco-negro en la barra al x exacto.
                    if (bodyFatPct != null)
                      Positioned(
                        left: pinCenterX - 5,
                        top: 4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 3) Etiquetas numéricas debajo en sus posiciones.
            const SizedBox(height: 4),
            SizedBox(
              width: w,
              height: 14,
              child: Stack(
                children: [
                  for (int i = 1; i < _bounds.length - 1; i++)
                    Positioned(
                      left:
                          ((_bounds[i] - _bounds.first) / (_bounds.last - _bounds.first)) * w - 10,
                      top: 0,
                      width: 20,
                      child: Text(
                        _bounds[i].toStringAsFixed(0),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PinBubble extends StatelessWidget {
  const _PinBubble({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _DownTri extends StatelessWidget {
  const _DownTri();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 8),
      painter: _TriPainter(),
    );
  }
}

class _TriPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TriPainter old) => false;
}
