import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/calendar_state_provider.dart';

class WeeklyCalendarStrip extends ConsumerWidget {
  const WeeklyCalendarStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(calendarStateProvider);
    final canGoNext = ref.read(calendarStateProvider.notifier).canGoNextWeek;
    
    // Calculate start of the visible week (Monday) based on selected date
    final currentWeekday = selectedDate.weekday; // 1=Mon
    final monday = selectedDate.subtract(Duration(days: currentWeekday - 1));
    
    final days = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    return Column(
      children: [
        // Navigation Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Text(
                DateFormat('MMMM yyyy', 'es_ES').format(selectedDate).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(calendarStateProvider.notifier).prevWeek(),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: canGoNext ? null : Colors.grey[300]),
                onPressed: canGoNext ? () => ref.read(calendarStateProvider.notifier).nextWeek() : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Days Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((date) {
            final now = DateTime.now();
            final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
            final isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;

            Color backgroundColor;
            Color textColor;

            if (isToday) {
              backgroundColor = Colors.green; 
              textColor = Colors.white;
            } else if (isSelected) {
              backgroundColor = AppTheme.brandBlue; 
              textColor = Colors.white;
            } else {
              backgroundColor = Colors.grey.shade100;
              textColor = Colors.grey.shade600;
            }

            return GestureDetector(
              onTap: () {
                ref.read(calendarStateProvider.notifier).selectDate(date);
              },
          child: Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekDayLetter(date.weekday),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
      ],
    );
  }

  String _weekDayLetter(int weekday) {
    const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return letters[weekday - 1];
  }
}
