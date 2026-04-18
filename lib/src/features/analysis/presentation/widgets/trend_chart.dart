import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'dart:math' as math;

class TrendChart extends StatefulWidget {
  final List<double> data;
  final String label;
  final Color color;

  const TrendChart({
    super.key,
    required this.data,
    required this.label,
    this.color = const Color(0xFF10B981),
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 1.5,
                ),
              ),
              if (_selectedIndex != null)
                Text(
                  'VALOR: ${widget.data[_selectedIndex!].toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) => _handleTouch(details.localPosition.dx, context),
              onTapDown: (details) => _handleTouch(details.localPosition.dx, context),
              child: CustomPaint(
                size: Size.infinite,
                painter: _LineChartPainter(
                  data: widget.data,
                  color: widget.color,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTouch(double x, BuildContext context) {
    final width = context.size?.width ?? 1.0;
    final itemWidth = width / (widget.data.length - 1);
    final index = (x / itemWidth).round().clamp(0, widget.data.length - 1);
    setState(() => _selectedIndex = index);
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final int? selectedIndex;

  _LineChartPainter({
    required this.data,
    required this.color,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final double stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.8 + (size.height * 0.1));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw selection indicator
    if (selectedIndex != null && selectedIndex! < data.length) {
      final x = selectedIndex! * stepX;
      final y = size.height - ((data[selectedIndex!] - minVal) / range * size.height * 0.8 + (size.height * 0.1));

      final selectPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 6, selectPaint);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      
      // Vertical line
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
