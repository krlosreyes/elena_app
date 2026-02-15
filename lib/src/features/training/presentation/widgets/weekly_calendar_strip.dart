import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../application/selected_date_provider.dart';

class WeeklyCalendarStrip extends ConsumerWidget {
  const WeeklyCalendarStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    
    // Calculate week start (Monday) based on selected date (or stick to current week if we want that behavior)
    // Requirement says "date-based calendar", typically allows navigation.
    // Let's create a strip of 7 days around the *current* view week. 
    // Simplified: Always show THIS week (Monday to Sunday) for now. Navigation to other weeks would require more UI.
    // Assuming "current week" for MVP based on context. 
    
    final currentWeekDay = now.weekday; // 1=Mon
    final monday = now.subtract(Duration(days: currentWeekDay - 1));
    
    final days = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((date) {
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
            ref.read(selectedDateProvider.notifier).selectDate(date);
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
                    color: textColor.withOpacity(0.8),
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
    );
  }

  String _weekDayLetter(int weekday) {
    const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return letters[weekday - 1];
  }
}
