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
                style: GoogleFonts.firaCode(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () => ref.read(calendarStateProvider.notifier).prevWeek(),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: canGoNext ? Colors.white70 : Colors.white24),
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
            BoxBorder? border;

            if (isToday) {
              backgroundColor = const Color(0xFF00FFB2).withOpacity(0.2); 
              textColor = const Color(0xFF00FFB2);
              border = Border.all(color: const Color(0xFF00FFB2).withOpacity(0.5));
            } else if (isSelected) {
              backgroundColor = Colors.blueAccent.withOpacity(0.2); 
              textColor = Colors.blueAccent;
              border = Border.all(color: Colors.blueAccent.withOpacity(0.5));
            } else {
              backgroundColor = Colors.white.withOpacity(0.05);
              textColor = Colors.grey.shade500;
              border = Border.all(color: Colors.white10);
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
              border: border,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekDayLetter(date.weekday),
                  style: GoogleFonts.firaCode(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
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
