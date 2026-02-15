import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/performance_provider.dart';

class WeekCalendar extends ConsumerWidget {
  final int checkInDay; // 1 = Lunes
  final VoidCallback onCheckInTap;

  const WeekCalendar({
    super.key, 
    required this.checkInDay,
    required this.onCheckInTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(weeklyPerformanceProvider);
    final now = DateTime.now();
    // Inicio de semana (Lunes)
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 12),
            child: Text(
              'Tu Semana',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayNum = index + 1; // 1 (Mon) - 7 (Sun)
              final dayDate = monday.add(Duration(days: index));
              final isToday = dayNum == now.weekday;
              
              // Normalizar fecha para buscar en el mapa de scores
              final dayKey = DateTime(dayDate.year, dayDate.month, dayDate.day);
              final isFuture = dayKey.isAfter(DateTime(now.year, now.month, now.day));

              return performanceAsync.when(
                data: (scores) {
                  final score = scores[dayKey] ?? 0;
                  return _buildDayCell(context, dayNum, dayDate, isToday, isFuture, score);
                },
                loading: () => _buildDayCell(context, dayNum, dayDate, isToday, isFuture, 0, isLoading: true),
                error: (_, __) => _buildDayCell(context, dayNum, dayDate, isToday, isFuture, 0),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context, 
    int dayNum, 
    DateTime date, 
    bool isToday, 
    bool isFuture, 
    int score, 
    {bool isLoading = false}
  ) {
    Color bgColor;
    Color textColor;
    BoxBorder? border;

    if (isLoading) {
      bgColor = Colors.grey[50]!;
      textColor = Colors.grey[300]!;
    } else if (isFuture) {
      bgColor = Colors.transparent;
      textColor = Colors.grey[400]!;
    } else {
      // Días pasados / Hoy -> Semáforo
      switch (score) {
        case 3:
          bgColor = const Color(0xFF4CAF50); // Green
          textColor = Colors.white;
          break;
        case 2:
          bgColor = const Color(0xFFFF9800); // Orange
          textColor = Colors.white;
          break;
        default: // 0 or 1
          bgColor = const Color(0xFFEF5350); // Red
          textColor = Colors.white;
          break;
      }
    }

    // Indicador de selección si es hoy (borde azul o similar, pero manteniendo el color de fondo)
    if (isToday) {
      border = Border.all(
        color: Theme.of(context).primaryColor,
        width: 2,
      );
    }

    return Column(
      children: [
        Text(
          _dayLetter(dayNum),
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: (isToday) ? onCheckInTap : null, // Solo permitir tap hoy para check-in rápido si se desea
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: border,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dayLetter(int day) {
    const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return letters[day - 1];
  }
}
