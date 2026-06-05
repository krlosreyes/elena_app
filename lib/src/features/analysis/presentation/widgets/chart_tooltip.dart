// SPEC-168.7 (2026-06-04): tooltip flotante para charts. Se muestra al
// tap en una barra o punto y comunica el valor exacto + fecha del
// bucket. Patrón Apple Fitness/Health.
//
// El layout es un Stack que aprovecha todo el área del chart. El
// `Positioned` interno calcula la x sin salirse del plot.

import 'package:flutter/material.dart';

class ChartTooltip extends StatelessWidget {
  const ChartTooltip({
    super.key,
    required this.anchorX,
    required this.plotRight,
    required this.value,
    required this.unit,
    required this.dateText,
  });

  /// X (en pixels del chart) del bucket seleccionado — centro del slot.
  final double anchorX;

  /// X derecho del plot (donde termina la barra). Para clamp del pill.
  final double plotRight;

  /// Valor agregado ya formateado ("16.4", "78.0", "82").
  final String value;

  /// Unidad ("h", "kg", "%", "L", "min"). Puede ser vacío.
  final String unit;

  /// Fecha humana ("5 jun. de 2026", "Sem del 5 jun.", "jun. 2026").
  final String dateText;

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate: _TooltipLayoutDelegate(
        anchorX: anchorX,
        plotRight: plotRight,
      ),
      children: [
        LayoutId(
          id: 'pin',
          child: _PinBubble(value: value, unit: unit, date: dateText),
        ),
        LayoutId(
          id: 'tail',
          child: const _DownTail(),
        ),
      ],
    );
  }
}

class _TooltipLayoutDelegate extends MultiChildLayoutDelegate {
  _TooltipLayoutDelegate({
    required this.anchorX,
    required this.plotRight,
  });

  final double anchorX;
  final double plotRight;

  @override
  void performLayout(Size size) {
    // Pin: lo más alto que pueda (top: 2). Centramos en anchorX
    // pero limitamos para no salirnos del plot.
    final pinSize = layoutChild(
      'pin',
      BoxConstraints.loose(Size(plotRight, 60)),
    );
    final pinLeft =
        (anchorX - pinSize.width / 2).clamp(0.0, plotRight - pinSize.width);
    positionChild('pin', Offset(pinLeft, 2));

    // Cola: justo debajo del pin, centrada en anchorX exacto.
    final tailSize = layoutChild(
      'tail',
      const BoxConstraints.tightFor(width: 12, height: 8),
    );
    positionChild(
      'tail',
      Offset(anchorX - tailSize.width / 2, 2 + pinSize.height),
    );
  }

  @override
  bool shouldRelayout(covariant _TooltipLayoutDelegate old) =>
      old.anchorX != anchorX || old.plotRight != plotRight;
}

class _PinBubble extends StatelessWidget {
  const _PinBubble({
    required this.value,
    required this.unit,
    required this.date,
  });

  final String value;
  final String unit;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DownTail extends StatelessWidget {
  const _DownTail();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(12, 8), painter: _TailPainter());
  }
}

class _TailPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _TailPainter old) => false;
}
