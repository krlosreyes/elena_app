import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/performance_provider.dart';

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
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    // Compute gradient alignment based on today's weekday
    final todayIndex = now.weekday - 1; // 0-6
    final gradientX = -1.0 + (todayIndex / 3.0);
    final gradientBegin = Alignment(gradientX, 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: gradientBegin,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF00FFB2).withOpacity(0.10),
            const Color(0xFF009688).withOpacity(0.04),
            Colors.white.withOpacity(0.02),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00FFB2).withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFB2).withOpacity(0.06),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (index) {
        final dayNum = index + 1;
        final dayDate = monday.add(Duration(days: index));
        final isToday = dayNum == now.weekday;
        final dayKey = DateTime(dayDate.year, dayDate.month, dayDate.day);
        final isFuture = dayKey.isAfter(DateTime(now.year, now.month, now.day));

        return Expanded(
          child: performanceAsync.when(
            data: (scores) {
              final score = scores[dayKey] ?? 0;
              return _DayChip(
                dayNum: dayNum,
                date: dayDate,
                isToday: isToday,
                isFuture: isFuture,
                score: score,
                onTap: isToday ? onCheckInTap : null,
              );
            },
            loading: () => _DayChip(
              dayNum: dayNum,
              date: dayDate,
              isToday: isToday,
              isFuture: isFuture,
              score: 0,
              isLoading: true,
            ),
            error: (_, __) => _DayChip(
              dayNum: dayNum,
              date: dayDate,
              isToday: isToday,
              isFuture: isFuture,
              score: 0,
            ),
          ),
        );
        }),
      ),  // Row
    );    // Container
  }
}

// ─── Individual day chip ─────────────────────────────────────────────────────
class _DayChip extends StatelessWidget {
  final int dayNum;
  final DateTime date;
  final bool isToday;
  final bool isFuture;
  final int score;
  final bool isLoading;
  final VoidCallback? onTap;

  const _DayChip({
    required this.dayNum,
    required this.date,
    required this.isToday,
    required this.isFuture,
    required this.score,
    this.isLoading = false,
    this.onTap,
  });

  static const _letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  Color get _dotColor {
    if (isLoading || isFuture) return Colors.transparent;
    switch (score) {
      case 3: return const Color(0xFF00FFB2);
      case 2: return Colors.orange;
      default: return const Color(0xFFEF5350);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Today: teal glow circle
    // Past with data: colored dot below number
    // Future: dimmed
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day letter
          Text(
            _letters[dayNum - 1],
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? const Color(0xFF00FFB2)
                  : isFuture
                      ? Colors.white24
                      : Colors.white38,
            ),
          ),
          const SizedBox(height: 4),

          // Day number circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday
                  ? const Color(0xFF009688).withOpacity(0.25)
                  : Colors.transparent,
              border: isToday
                  ? Border.all(color: const Color(0xFF00FFB2), width: 1.5)
                  : null,
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FFB2).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
                  color: isToday
                      ? const Color(0xFF00FFB2)
                      : isFuture
                          ? Colors.white24
                          : Colors.white60,
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          // Performance dot (past days only)
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _dotColor,
            ),
          ),
        ],
      ),
    );
  }
}
